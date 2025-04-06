using topSU3, DataFrames, ADerrors, Plots, JLD2, ArgParse, TOML, Serialization, BDIO, ALPHAio

params = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")


ENSEMBLE_LIST = ["SuperCoarse","Coarse-1","Coarse-2","Fine-1","Fine-2"]
FLOW_LIST     = ["wilson","lw","dbw2"]
C_LIST        = [0.2,0.25,0.3,0.35,0.4,0.45,0.5]

confrange = Dict(
    "SuperCoarse" => 20:20:20000,
    "Coarse-1"    => 20:20:20020,
    "Coarse-2"    => 20:20:19980,
    "Fine-1"      => 1000:140:131460,
    "Fine-2"      => 3400:600:432400,    
)


## ======================== Read flow data ============================
    flw_dict = Dict()
    for ens in ENSEMBLE_LIST
        flw_dict[ens] = Dict()
        for flow in ["wilson","lw","dbw2"]
            @info("Loading $ens $flow")
            @load params["ensembles"][ens][flow]["file"] flw_data
            flw_dict[ens][flow] = flw_data
        end
    end
## ========================== Unify MC histories ========================
    for (ens,ff) in flw_dict
        confn = [unique(f.itraj) for (ker,f) in ff]
        lst = intersect(confn...)

        for (ker,f) in ff
            unify_mch!(flw_dict[ens][ker],lst)     
        end
    end
## =====================================================================





















## ========================= COMPUTE PRIMARY OBSERVABLES =================

    scales = DataFrame(
        ensemble  = String[],
        flow_type = String[],
        L         = Int[],
        obs       = String[],
        ref       = Float64[],
        t0        = uwreal[],
    )
    top = DataFrame(
        ensemble  = String[],
        flow_type = String[],
        L         =  Int[],
        scheme    =  Float64[],
        t_cut     =  Float64[],
        τ         =  Tuple[],
        χ         =  uwreal[],
        χround    =  uwreal[]
    )
##
    for ens in ENSEMBLE_LIST
        lsize  = params["ensembles"][ens]["size"]

        for flow in FLOW_LIST
            fd = flw_dict[ens][flow]

            @info("Analyzing data for $ens with $flow...")

            # Scale setting ------------------------------------
                fd.t2Eimp = 
                    (4. .* fd.t2Eplq .- fd.t2Esym) ./ 3.
            
                for obs in [:t2Eplq, :t2Esym, :t2Eimp]
                    for r in [0.15,0.3,0.5]
                        @info("      Computing scales ($obs, $r)")
                        t0, _,_ = set_scale(fd, ens, lsize; tcut=r , obs=obs)
                        push!(scales,(ens,flow,lsize,String(obs),r,t0))
                    end
                end

            # Topology -----------------------------------------
                for c in C_LIST
                    @info("                       : scheme = $c...")
                    Tcut = (lsize*c)^2/8
                    tau, χ, χround = topology(fd, ens, lsize, Tcut)
                    push!(top,(ens,flow,lsize,c,Tcut,tau,χ,χround))
                end
        end
    end
## =====================================================================


##
dump_data_dic(scales, "RESULTS/apr4_scales"  ; keys=["ensemble","flow_type","L","obs","ref"], values=["t0"])
dump_data_dic(top   , "RESULTS/apr4_topology"; keys=["ensemble","flow_type","L","scheme"], values=["χ","χround"])

##
    scale = reconstruct("RESULTS/apr4_scales.bdio"  , keys=["ensemble","flow_type","L","obs","ref"], values=["t0"])
    topol = reconstruct("RESULTS/apr4_topology.bdio", keys=["ensemble","flow_type","L","scheme"], values=["χ","χround"])
