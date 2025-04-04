using topSU3, DataFrames, ADerrors, Plots, JLD2, ArgParse, TOML, Serialization, BDIO, ALPHAio

metap = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")
params = metap["ensembles"]


ENSEMBLE_LIST = ["SuperCoarse","Coarse-1","Coarse-2","Fine-1","Fine-2"]
FLOW_LIST     = ["lw","wilson","dbw2"]
C_LIST        = [0.2,0.25,0.3,0.35,0.4,0.45,0.5]


## =========== Unify mc histories ==================
unif = Dict()
for ens in ENSEMBLE_LIST
    @info("$ens")


    @load params[ens]["wilson"]["file"] flw_data
    wi = flw_data
    @load params[ens]["lw"    ]["file"] flw_data
    lw = flw_data
    @load params[ens]["dbw2"  ]["file"] flw_data
    db = flw_data

    tr1 = unique(wi.itraj) 
    tr2 = unique(lw.itraj) 
    tr3 = unique(db.itraj) 

    if !(tr1==tr2==tr3)
        @warn("take care of me")
    end

    confs = intersect(tr1,tr2,tr3)
    unif[ens] = confs
end
## =================================================





results = DataFrame(
    ensemble  = String[],
    flow_type = String[],
    L        =  Int[],
    wf_scale =  uwreal[],
    a_fm     =  uwreal[],
    volume   =  uwreal[],
    scheme   =  Float64[],
    t_cut    =  Float64[],
    τ        =  Tuple[],
    χ        =  uwreal[],
    χround   =  uwreal[]
)
for ens in ENSEMBLE_LIST
    lsize  = params[ens]["size"]
    for flow in FLOW_LIST
        @info("Reading data for $ens...")
        # Read file ----------------------------------------
            @load params[ens][flow]["file"] flw_data

            flw_data = filter(row->row.itraj∈unif[ens], flw_data)

        @info("Analyzing data for $ens...")
        # Scale setting ------------------------------------
            scale, a_fm, volume = set_scale(flw_data, ens, lsize)

            for c in C_LIST
                @info("                       : scheme = $c...")
                # Topology -----------------------------------------
                    Tcut = (lsize*c)^2/8
                    tau, χ, χround = topology(flw_data, ens, lsize, Tcut)

                push!(results,(ens,flow,lsize,scale,a_fm,volume,c,Tcut,tau,χ,χround))
            end
    end
end

dump_data_dic(results, "RESULTS/apr3")

##
    params = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")
    df = reconstruct("RESULTS/apr3",params)