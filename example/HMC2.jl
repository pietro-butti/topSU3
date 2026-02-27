using LatticeGPU
using Printf, TimerOutputs, ProgressMeter
using CUDA
using ArgParse
using TOML

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--L"
            help = "Lattice size in x direction"
            arg_type = Int
            required = true
        "--Lx"
            help = "Sub-lattice size in x direction"
            arg_type = Int
            default = 8
        "--beta", "-b"
            help = "Inverse coupling constant β"
            arg_type = Float64
            required = true
        "--c0"
            help = "Symanzik coefficient c₀"
            arg_type = Float64
            default = 1.
        "--delta"
            help = "HMC step size δ"
            arg_type = Float64
            default = 0.01
        "--nleaps"
            help = "Number of leapfrog steps"
            arg_type = Int
            default = 50
        "--ntherm"
            help = "Number of thermalization steps"
            arg_type = Int
            default = 100
        "--ntraj"
            help = "Number of trajectories"
            arg_type = Int
            required = true
        "--epsilon"
            help = "Flow step size ϵ"
            arg_type = Float64
            default = 0.01
        "--nflow"
            help = "Number of flow steps"
            arg_type = Int
            default = 100
        "--flow-each"
            help = "Perform flow every N trajectories"
            arg_type = Int
            required = true
        "--saveto"
            help = "Directory to save configurations"
            arg_type = String
            default = "./"
        "--ens-name"
            help = "Ensemble name"
            arg_type = String
            default = "random_run"
        "--save-each"
            help = "Save configuration every N trajectories"
            arg_type = Int
            default = 9999
        "--GPU"
            help = "Device number"
            arg_type = Int
            default = 0
    end

    return parse_args(s)
end

function parse_input()
    aps = ArgParseSettings()

    @add_arg_table aps begin 
        "-i"
        help = "input file"
        required = true
        arg_type = String
        "-a"
        help = "append to existing run"
        action = :store_true
    end

    s = parse_args(aps)

    append = s["a"]
    ds = TOML.parsefile(s["i"])
    return ds
end


function main()
    # args = parse_commandline()
    ds = parse_input()
    
    ## ============================================================================
    # Geometry
        # Run
        USER     = ds["Run"]["user"]
        HOST     = ds["Run"]["host"]
        NAME     = ds["Run"]["name"]
        ENS_NAME = ds["Run"]["ensName"]
        DEVICE   = ds["Run"]["device"]
        
        # Lattice
        VOL   = Tuple(ds["Lattice"]["size"]) 
        SVOL  = Tuple(ds["Lattice"]["blocks"]) 
        β     = ds["Lattice"]["beta"]
        c₀    = ds["Lattice"]["c0"]
        TWIST = Tuple(ds["Lattice"]["twist"])
        BC    = ds["Lattice"]["bcs"]

        # HMC
        NTHERM = ds["HMC"]["ntherm"]
        NTRAJ  = ds["HMC"]["ntraj"]
        NLEAPS = ds["HMC"]["nleaps"]
        δ      = ds["HMC"]["delta"]

        # Flow
        ϵ         = ds["Flow"]["eps"]
        TOL       = ds["Flow"]["tol"]
        NFLOW     = ds["Flow"]["nflow"]
        FLOW_EACH = ds["Flow"]["flowEach"]

        # Logs
        SAVETO    = ds["Logs"]["saveto"]
        SAVE_EACH = ds["Logs"]["saveEach"]
    ## ============================================================================

    device!(DEVICE)

    println("# === Configuration ===")
    println("[PARAMETER LOG] User: $(USER)")
    println("[PARAMETER LOG] Host: $(HOST)")
    println("[PARAMETER LOG] Run Name: $(NAME)")
    println("[PARAMETER LOG] Lattice: $(VOL)")
    println("[PARAMETER LOG] Sub-lattice: $(SVOL)")
    println("[PARAMETER LOG] β = $β, c₀ = $c₀")
    println("[PARAMETER LOG] HMC: δ=$δ, nleaps=$NLEAPS")
    println("[PARAMETER LOG] Thermalization: $NTHERM, Trajectories: $NTRAJ")
    println("[PARAMETER LOG] Flow: ϵ=$ϵ, nflow=$NFLOW, every $FLOW_EACH trajectories")
    println("[PARAMETER LOG] Save to: $SAVETO, ensemble: $ENS_NAME")


    ## ----------------- Setting parameters and plaquette check --------------------
        lp = SpaceParm{4}(VOL, SVOL, BC, TWIST)
        gp = GaugeParm{Float64}(SU3{Float64}, β, c₀, (1.0,1.0), (0.0,0.0), lp.iL)

        wflw = wfl_rk3(Float64, ϵ, TOL)
        intsch = omf4(Float64, δ, NLEAPS)

        ymws = YMworkspace(SU3, Float64, lp);

        U = vector_field(SU3{Float64}, lp);
        fill!(U, one(SU3{Float64}));

        plq = plaquette(U, lp, gp, ymws)
        println("plq = $(plq/2)")

        CNFG = 0
    ## --------------------------------------------------------------------

    ## Thermalize
    for _ in 1:NTHERM
        HMC!(U, intsch, lp, gp, ymws)
        CNFG += 1
        plq, qtop, qrec = plaquette(U, lp, gp, ymws), Qtop(U, gp, lp, ymws), Qtop_rect(U, gp, lp, ymws)
        @printf "[ THERMALIZATION ][ CONF %06i ] %17.16e %17.16e %17.16e \n" CNFG plq qtop qrec
    end

    U0_CPU = Array(U);

    ## HMC and flow
    for tmc in 1:NTRAJ
        dh, acc = HMC!(U, intsch, lp, gp, ymws)
        CNFG += 1
        @printf "[ HMC ][ CONF %06i ]: Delta H %17.16e \n" CNFG dh
        println("[ HMC ][ CONF $CNFG ]: Config accepted : ", acc)

        plq, qtop, qrec = plaquette(U, lp, gp, ymws), Qtop(U, gp, lp, ymws), Qtop_rect(U, gp, lp, ymws)
        @printf "[ HMC ][ CONF %06i ] %17.16e %17.16e %17.16e \n" CNFG plq qtop qrec

        if (CNFG-1-NTHERM) % FLOW_EACH == 0
            # Buffer unflowed config to CPU
            U0_CPU .= Array(U)

            println("### Flow [CONF $CNFG]  ###")
            plaq = plaquette(U, lp, gp, ymws)
            Eplq = Eoft_plaq(U, gp, lp, ymws)
            Eclv = Eoft_clover(U, gp, lp, ymws)
            qtop = Qtop(U, gp, lp, ymws)
            qrec = Qtop_rect(U, gp, lp, ymws)

            ft = 0.
            @printf "# time Eplt t²Eplq Eclv t²Eclv qtop qrec \n"
            @printf "[ FLOW ][ CONF %06i ] %17.16e %17.16e %17.16e %17.16e %17.16e %17.16e  %17.16e \n" CNFG ft Eplq ft^2*Eplq Eclv ft^2*Eclv qtop qrec

            for t in 1:NFLOW
                ft = t*ϵ
                flw(U, wflw, 1, ϵ, gp, lp, ymws)
                plaq = plaquette(U, lp, gp, ymws)
                Eplq = Eoft_plaq(U, gp, lp, ymws)
                Eclv = Eoft_clover(U, gp, lp, ymws)
                qtop = Qtop(U, gp, lp, ymws)
                qrec = Qtop_rect(U, gp, lp, ymws)
                @printf "[ FLOW ][ CONF %06i ] %17.16e %17.16e %17.16e %17.16e %17.16e %17.16e  %17.16e \n" CNFG ft Eplq ft^2*Eplq Eclv ft^2*Eclv qtop qrec
            end

            # Retrieve unflowed conf for HMC
            copyto!(U, U0_CPU)
        end

        if (CNFG-NTHERM) % SAVE_EACH == 0
            name = "$(ENS_NAME).cfg_n$CNFG"
            file = joinpath(SAVETO, name)
            save_cnfg(file, U, lp, gp)
            println("[ IO ][ CONF $CNFG ] conf saved in $file")
        end
    end

    print_timer()
end

# Run main function
main()