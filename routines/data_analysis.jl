using topSU3, DataFrames, ADerrors, Plots, JLD2, ArgParse, TOML, Serialization, BDIO, ALPHAio


function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--metaparams", "-i"
            arg_type = String
            default  = "/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml"
        "--readfrom"
            arg_type = String
            default  = ""
        "--saveto"
            arg_type = String
            default  = ""
        "--prefix"
            arg_type = String
            default  = "analysis"
        "--verbose", "-v"
            help = "Enable verbose output"
            action = :store_true

        "--ensembles", "-e"
            help = "List of files to analyze"
            nargs = '+'
            arg_type = String
            default = []
        "--flow", "-f"
            help = "Type of Wilson flow to consider (default: only Wilson)"
            nargs = '+'
            arg_type = String
            default = ["wilson"]

        "--scheme", "-c"
            help = "c = √(8T₀)/L"
            nargs = '+'
            arg_type = Float64
            default = []
        
    end

    return parse_args(s)
end

function main()
    pargs = parse_commandline()
    
    metap = TOML.parsefile(pargs["metaparams"])
    params = metap["ensembles"]

    ensemble_list = isempty(pargs["ensembles"]) ?  keys(params) : pargs["ensembles"]
    flow_list     = pargs["ensembles"]
    scheme_list   = pargs["scheme"] 

    df = run_analysis(
        ensemble_list,
        flow_list,
        scheme_list,
        metap,
        verbose = pargs["verbose"]
    )

    if pargs["verbose"]
        println(df)
    end

    if pargs["saveto"]!=="" && isdir(pargs["saveto"])
        savedir = pargs["saveto"]
        prefix  = pargs["prefix"]
        bdio_dump(df; saveto=savedir, prefix=prefix)
    end

    return df
end

##

df = run_analysis(
    ["SuperCoarse","Coarse-1","Coarse-2","Fine-1","Fine-2"],
    ["wilson"],
    [0.2,0.25,0.3,0.35,0.4,0.45,0.5],
    TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")
)
##

dump_data_dic(df, "RESULTS/wilson")

##
using topSU3, DataFrames, ADerrors, Plots, JLD2, ArgParse, TOML, Serialization, BDIO, ALPHAio
params = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")
df = reconstruct("RESULTS/wilson",params)