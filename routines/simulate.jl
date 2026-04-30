using LatticeGPU
using Printf, TimerOutputs, ProgressMeter
using CUDA
using ArgParse
using TOML

# ==============================================================================
#  ARGUMENT PARSING
# ==============================================================================

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--input-file"
            help = "Path to a TOML input file. If provided, all other flags are ignored."
            arg_type = String
            default = nothing

        # --- Geometry ---
        "--L"
            help = "Lattice size (full, all directions)"
            arg_type = Int
        "--Lx"
            help = "Sub-lattice size (all directions)"
            arg_type = Int
            default = 8

        # --- Action ---
        "--beta", "-b"
            help = "Inverse coupling constant β"
            arg_type = Float64
        "--c0"
            help = "Symanzik coefficient c₀ (action)"
            arg_type = Float64
            default = 1.0

        # --- HMC ---
        "--ntherm"
            help = "Number of thermalization trajectories"
            arg_type = Int
            default = 100
        "--ntraj"
            help = "Number of production trajectories"
            arg_type = Int
        "--delta"
            help = "HMC integrator step size δ"
            arg_type = Float64
            default = 0.1
        "--nleaps"
            help = "Number of leapfrog steps per trajectory"
            arg_type = Int
            default = 10

        # --- Gradient flow ---
        "--flow-each"
            help = "Perform gradient flow every N trajectories"
            arg_type = Int
        "--zeuthen"
            help = "Use Zeuthen flow (default: Wilson flow)"
            action = :store_true
        "--adaptive"
            help = "Use adaptive step-size for the flow"
            action = :store_true
        "--Tflow"
            help = "Maximum flow time (required for adaptive flow)"
            arg_type = Float64
            default = -1.0
        "--c0flow"
            help = "Symanzik coefficient c₀ in the flow kernel"
            arg_type = Float64
            default = 1.0
        "--epsilon"
            help = "Flow step size ϵ (fixed-step flow)"
            arg_type = Float64
            default = 0.01
        "--nflow"
            help = "Number of flow steps (fixed-step flow)"
            arg_type = Int
            default = 100

        # --- I/O ---
        "--saveto"
            help = "Directory for saving gauge configurations"
            arg_type = String
            default = "./"
        "--ens-name"
            help = "Ensemble identifier used in file names"
            arg_type = String
            default = "random_run"
        "--save-each"
            help = "Save configuration every N trajectories"
            arg_type = Int
            default = 9999
        "--start-from"
            help = "Path to a starting configuration file (optional; starts from unit otherwise)"
            arg_type = String
            default = nothing
        "--GPU"
            help = "CUDA device index"
            arg_type = Int
            default = 0
    end

    return parse_args(s)
end


# ==============================================================================
#  TOML PARAMETER LOADING
# ==============================================================================

"""
    load_params_from_toml(path)

    Read simulation parameters from a TOML file and return them as a Dict
    with the same keys used by the CLI parser.

    Example TOML (`input.toml`):
    ─────────────────────────────────────────────────────────────────────────────
    [geometry]
    L  = 16
    Lx = 8

    [action]
    beta = 6.2
    c0   = 1.0

    [hmc]
    ntherm = 200
    ntraj  = 1000
    delta  = 0.02
    nleaps = 20

    [flow]
    flow_each = 5
    zeuthen   = false
    adaptive  = false
    Tflow     = -1.0
    c0flow    = 1.0
    epsilon   = 0.01
    nflow     = 100

    [io]
    saveto     = "./output"
    ens_name   = "b6.2_L16"
    save_each  = 10
    start_cnfg = ""        # leave empty to start from unit configuration
    GPU        = 0
    ─────────────────────────────────────────────────────────────────────────────
"""
function load_params_from_toml(path::String)
    raw = TOML.parsefile(path)

    geo  = get(raw, "geometry", Dict())
    act  = get(raw, "action",   Dict())
    hmc  = get(raw, "hmc",      Dict())
    flow = get(raw, "flow",     Dict())
    io   = get(raw, "io",       Dict())

    return Dict{String,Any}(
        # geometry
        "L"          => geo["L"],
        "Lx"         => get(geo, "Lx", 8),
        # action
        "beta"       => act["beta"],
        "c0"         => get(act, "c0", 1.0),
        # hmc
        "ntherm"     => get(hmc, "ntherm", 100),
        "ntraj"      => hmc["ntraj"],
        "delta"      => get(hmc, "delta",  0.01),
        "nleaps"     => get(hmc, "nleaps", 50),
        # flow
        "flow-each"  => flow["flow_each"],
        "zeuthen"    => get(flow, "zeuthen",  false),
        "adaptive"   => get(flow, "adaptive", false),
        "Tflow"      => get(flow, "Tflow",   -1.0),
        "c0flow"     => get(flow, "c0flow",   1.0),
        "epsilon"    => get(flow, "epsilon",  0.01),
        "nflow"      => get(flow, "nflow",    100),
        # io
        "saveto"     => get(io, "saveto",     "./"),
        "ens-name"   => get(io, "ens_name",   "random_run"),
        "save-each"  => get(io, "save_each",  9999),
        "start-from" => get(io, "start_cnfg", nothing),
        "GPU"        => get(io, "GPU",         0),
    )
end


# ==============================================================================
#  PARAMETER LOGGING
# ==============================================================================

function print_parameter_banner(args)
    sep = "# " * "="^74

    println(sep)
    println("# === SIMULATION PARAMETERS ===")
    println(sep)

    println("#")
    println("# [GEOMETRY]")
    println("#   Lattice volume  : $(args["L"])^4")
    println("#   Sub-lattice     : $(args["Lx"])^4")

    println("#")
    println("# [ACTION]")
    println("#   β               : $(args["beta"])")
    println("#   c₀              : $(args["c0"])")

    println("#")
    println("# [HMC]")
    println("#   Thermalization  : $(args["ntherm"]) trajectories")
    println("#   Production      : $(args["ntraj"]) trajectories")
    println("#   Step size δ     : $(args["delta"])")
    println("#   Leapfrog steps  : $(args["nleaps"])")

    println("#")
    println("# [GRADIENT FLOW]")
    println("#   Flow every      : $(args["flow-each"]) trajectories")
    _kernel = args["zeuthen"] ? "Zeuthen" : "Wilson"
    println("#   Flow kernel     : $_kernel")
    println("#   c₀ (flow)       : $(args["c0flow"])")
    if args["adaptive"]
        println("#   Step-size       : adaptive  (T_max = $(args["Tflow"]))")
    else
        println("#   Step-size ϵ     : $(args["epsilon"])  (fixed, nsteps = $(args["nflow"]))")
    end

    println("#")
    println("# [I/O]")
    println("#   Ensemble name   : $(args["ens-name"])")
    println("#   Save directory  : $(args["saveto"])")
    println("#   Save every      : $(args["save-each"]) trajectories")
    _scnfg = isnothing(args["start-from"]) || args["start-from"] == "" ?
             "unit (cold start)" : args["start-from"]
    println("#   Starting config : $(_scnfg)")
    println("#   GPU device      : $(args["GPU"])")

    println("#")
    println(sep)
    flush(stdout)
end


# ==============================================================================
#  CONFIGURATION INITIALISATION
# ==============================================================================

"""
    init_gauge_field(lp, gp, start_cnfg)

Initialise the SU(3) gauge field `U`.

- If `start_cnfg` is `nothing` or an empty string the field is set to the
  unit element (cold start).
- Otherwise the configuration is loaded from the file at `start_cnfg` via
  `load_cnfg` (TO BE DEVELOPED).

Returns `(U, CNFG)` where `CNFG` is the trajectory counter embedded in the
file header (0 for a cold start).
"""
function init_gauge_field!(U, start_cnfg)
    if isnothing(start_cnfg) || start_cnfg == ""
        fill!(U, one(SU3{Float64}))
        cnfg = 0
        println("# [INIT] Cold start: gauge field set to unit.")
    else
        # ----------------------------------------------------------------
        # TO BE DEVELOPED: replace the two lines below with the actual
        # implementation once `load_cnfg` is available.
        #
        #   CNFG = load_cnfg!(U, start_cnfg, lp, gp)   # fills U in-place
        #   println("# [INIT] Loaded config from: $start_cnfg  (traj = $CNFG)")
        # ----------------------------------------------------------------
        error("Loading starting configurations is not yet implemented. " *
              "Provide `load_cnfg!` and uncomment the lines in `init_gauge_field`.")
    end

    return cnfg
end


# ==============================================================================
#  MAIN
# ==============================================================================

function main()
    # ---- Resolve parameters (CLI or TOML) --------------------------------
    raw_args = parse_commandline()

    args = if !isnothing(raw_args["input-file"])
        println("# Reading parameters from TOML file: $(raw_args["input-file"])")
        load_params_from_toml(raw_args["input-file"])
    else
        raw_args
    end

    # ---- Unpack ----------------------------------------------------------
    L         = args["L"]
    Lx        = args["Lx"]
    β         = args["beta"]
    c₀        = args["c0"]

    δ         = args["delta"]
    NLEAPS    = args["nleaps"]
    NTHERM    = args["ntherm"]
    NTRAJ     = args["ntraj"]

    ϵ         = args["epsilon"]
    ZEUTHEN   = args["zeuthen"]
    ADAPTIVE  = args["adaptive"]
    TFLOW     = args["Tflow"]
    NFLOW     = args["nflow"]
    FLOW_EACH = args["flow-each"]

    SAVETO    = args["saveto"]
    ENS_NAME  = args["ens-name"]
    SAVE_EACH = args["save-each"]
    START_CNFG = args["start-from"]

    # ---- Pretty-print all parameters -------------------------------------
    print_parameter_banner(args)

    # ---- CUDA device selection -------------------------------------------
    device!(args["GPU"])

    # ---- Lattice and gauge objects ---------------------------------------
    VOL  = (L,  L,  L,  L)
    SVOL = (Lx, Lx, Lx, Lx)

    lp = SpaceParm{4}(VOL, SVOL, BC_PERIODIC, (0,0,0,0,0,0))
    gp = GaugeParm{Float64}(SU3{Float64}, β, c₀, (1.0,1.0), (0.0,0.0), lp.iL)

    intsch = omf4(Float64, δ, NLEAPS)

    _wflw_ctor = ZEUTHEN ? wfl_rk3 : zfl_rk3
    wflw = _wflw_ctor(Float64, ϵ, 1.0E-7)

    if ADAPTIVE && TFLOW < 0
        error("Adaptive flow requires --Tflow to be set to a positive value.")
    end

    ymws = YMworkspace(SU3, Float64, lp)
    U = vector_field(SU3{Float64}, lp)

    # ---- Gauge field initialisation (cold or from file) ------------------
    CNFG = init_gauge_field!(U, START_CNFG)

    plq = plaquette(U, lp, gp, ymws)
    @printf "# [INIT] Initial plaquette = %17.16e\n" (plq/2)

    # CPU buffer for flow measurements (avoids re-allocating every time)
    U0_CPU = Array(U)

    # ==========================================================================
    # THERMALIZATION
    # ==========================================================================
    println("#")
    println("# --- Thermalization ($NTHERM trajectories) ---")

    for _ in 1:NTHERM
        dh, acc = HMC!(U, intsch, lp, gp, ymws)
        CNFG += 1
        plq   = plaquette(U, lp, gp, ymws)
        @printf "[ THERMALIZATION ][ CONF %06i ] - ΔH %17.16e [acc %01i] - Plaq %17.16e\n" CNFG dh acc plq
    end

    # ==========================================================================
    # PRODUCTION: HMC + GRADIENT FLOW
    # ==========================================================================
    println("#")
    println("# --- Production ($NTRAJ trajectories) ---")

    for tmc in 1:NTRAJ
        # -- HMC step ----------------------------------------------------------
        dh, acc = HMC!(U, intsch, lp, gp, ymws)
        CNFG   += 1
        plq     = plaquette(U, lp, gp, ymws)
        @printf "[ HMC ][ CONF %06i ] - ΔH %17.16e [acc %01i] - Plaq %17.16e\n" CNFG dh acc plq

        # -- Gradient flow measurement ----------------------------------------
        if (CNFG - 1 - NTHERM) % FLOW_EACH == 0
            U0_CPU .= Array(U)   # stash unflowed config before flowing

            println("### Flow [CONF $CNFG] ###")
            Eplq = Eoft_plaq(U, gp, lp, ymws)
            Eclv = Eoft_clover(U, gp, lp, ymws)
            qtop = Qtop(U, gp, lp, ymws)
            qrec = Qtop_rect(U, gp, lp, ymws)
            ft   = 0.0

            @printf "# time Eplq t²Eplq Eclv t²Eclv qtop qrec\n"
            @printf "[ FLOW ][ CONF %06i ] %17.16e %17.16e %17.16e %17.16e %17.16e %17.16e %17.16e\n" CNFG ft Eplq ft^2*Eplq Eclv ft^2*Eclv qtop qrec

            if !ADAPTIVE
                for t in 1:NFLOW
                    ft   = t * ϵ
                    flw(U, wflw, 1, ϵ, gp, lp, ymws)
                    Eplq = Eoft_plaq(U, gp, lp, ymws)
                    Eclv = Eoft_clover(U, gp, lp, ymws)
                    qtop = Qtop(U, gp, lp, ymws)
                    qrec = Qtop_rect(U, gp, lp, ymws)
                    @printf "[ FLOW ][ CONF %06i ] %17.16e %17.16e %17.16e %17.16e %17.16e %17.16e %17.16e\n" CNFG ft Eplq ft^2*Eplq Eclv ft^2*Eclv qtop qrec
                end
            else
                # TO BE DEVELOPED: adaptive flow
                # ns, eps_list = flw_adapt(U, wflw, TFLOW, gp, lp, ymws)
                error("Adaptive flow output loop not yet implemented.")
            end

            # Restore unflowed configuration for HMC to continue
            copyto!(U, U0_CPU)
        end

        # -- Configuration save -----------------------------------------------
        if (CNFG - 1 - NTHERM) % SAVE_EACH == 0
            name = "$(ENS_NAME).cfg_n$(CNFG)"
            file = joinpath(SAVETO, name)
            save_cnfg(file, U, lp, gp)
            @printf "[ IO ][ CONF %06i ] - conf saved in %s\n" CNFG file
        end
    end

    print_timer()
end

# ==============================================================================
main()