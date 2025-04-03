module AnalysisTools
    using DataFrames, ProgressMeter,ADerrors, Optim, Statistics, BDIO, JLD2, Serialization, ALPHAio
    using ..HiRep
    using ..Wflow

    include("AnalysisTools_formatting.jl")
        export read_flow_from_list 
        export inspect_flow_data, inspect_doublers, strip_confn, strip_confn!

    include("AnalysisTools_bdio.jl")
        # export bdio_dump, bdio_read
        export dump_data_dic, read_data_dic, reconstruct
    
    include("AnalysisTools_routines.jl")
        export set_scale, topology, run_analysis

end