using topSU3, DataFrames, ADerrors, Plots
using JLD2, ArgParse, TOML, Serialization
using BDIO, ALPHAio, LsqFit
using LaTeXStrings, Statistics
using LsqFit

using ADerrors
import ADerrors.err

params = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")
ENSEMBLE_LIST = ["SuperCoarse","Coarse-1","Coarse-2","Fine-1","Fine-2"]
FLOW_LIST = ["wilson","lw","dbw2"]


confrange = Dict(
    "SuperCoarse" => 20:20:20000,
    "Coarse-1"    => 20:20:20020,
    "Coarse-2"    => 20:20:19980,
    "Fine-1"      => 1000:140:131460,
    "Fine-2"      => 3400:600:432400,    
)

## ======================== Read flow data =============================
    flw_dict = Dict()
    for ens in ENSEMBLE_LIST
        flw_dict[ens] = Dict()
        for flow in ["wilson","lw","dbw2"]
            @info("Loading $ens $flow")
            @load params["ensembles"][ens][flow]["file"] flw_data
            flw_dict[ens][flow] = flw_data
        end
    end
## ========================== Unify MC histories [NO] =======================
    # for (ens,ff) in flw_dict
    #     confn = [unique(f.itraj) for (ker,f) in ff]
    #     lst = intersect(confn...)
        
    #     for (ker,f) in ff
    #         unify_mch!(flw_dict[ens][ker],lst)     
    #     end
    # end
## =====================================================================

