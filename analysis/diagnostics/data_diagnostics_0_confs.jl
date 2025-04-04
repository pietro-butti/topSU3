using topSU3, DataFrames, ADerrors, Plots
using JLD2, ArgParse, TOML, Serialization
using BDIO, ALPHAio, LsqFit
using LaTeXStrings, Statistics

using ADerrors
import ADerrors.err

params = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")
df = reconstruct("RESULTS/apr3",params)
ENSEMBLE_LIST = ["SuperCoarse","Coarse-1","Coarse-2","Fine-1","Fine-2"]
FLOW_LIST = ["wilson","lw","dbw2"]

##

flw_dict = Dict()
for ens in ENSEMBLE_LIST
    flw_dict[ens] = Dict()
    for flow in ["wilson","lw","dbw2"]
        @info("Loading $ens $flow")
        @load params["ensembles"][ens][flow]["file"] flw_data
        flw_dict[ens][flow] = flw_data
    end
end

##

confrange = Dict(
    "SuperCoarse" => 20:20:20000,
    "Coarse-1"    => 20:20:20020,
    "Coarse-2"    => 20:20:19980,
    "Fine-1"      => 1000:140:131460,
    "Fine-2"      => 3400:600:432400,    
)

mconfs = Dict()
for ens in ENSEMBLE_LIST
    confn = collect(confrange[ens])
    mconfs[ens] = Dict()

    for ker in FLOW_LIST
        trajs = unique(flw_dict[ens][ker].itraj)

        # Remove extra confs
        aux = filter(x-> x ∈ confn, trajs)
        # Remove missing confs
        miss = filter(x-> x∉trajs, confn)

        mconfs[ens][ker] = miss
    end
end


##
for ens in ENSEMBLE_LIST
    flw_ens = flw_dict[ens]
    confn = [d.itraj for (f,d) in flw_dict[ens]] 

    # c = unique.(confn)
    # println(ens," ",c[1][1]," ",c[2][1]," ",c[3][1])
    # println(ens," ",c[1][end]," ",c[2][end]," ",c[3][end])
end

## ========================= PLOT MISSING CONFS =========================
    plts = []
    
    for ens in ENSEMBLE_LIST
        flw_ens = flw_dict[ens]
        
        plt = plot() # --------------------------------------
        for (i,flow) in enumerate(["wilson","lw","dbw2"])
            confn = unique(flw_ens[flow].itraj)
            scatter!(
                plt,
                confn,ones(length(confn)).*i,
                msize=1,
                markerstrokewidth=0,
                label=""
            )
        end

        push!(plts,plt)
    end

    plt = plot(
        plts...,
        layout=(5,1),
        size=(1000,800),    
        yticks=(1:3,["wilson","lw","dbw2"]),
        titles=["SuperCoarse" "Coarse-1" "Coarse-2" "Fine-1" "Fine-2"],
    )
    display(plt)
## ======================================================================

