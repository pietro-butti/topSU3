module topSU3
    using DataFrames, Plots, ProgressMeter, Optim, Statistics, StatsBase, JLD2, Serialization
    using ADerrors, BDIO, ALPHAio, LsqFit

    include("IO/IO.jl")
    using .IO
        # export get_runtime, get_confn, get_plaquette
        export get_mc_history, get_flow_data


    include("Wflow/Wflow.jl")
    using .Wflow
        export slice_at, find_mismatch, find_incomplete_flow, find_doublers, strip_confs!, process_flow_data
        export find_optimal_alpha, Qtop
        export uwflow, tcut, tbounds, uwscale, confid

    # include("AnalysisTools/AnalysisTools.jl")
    # using .AnalysisTools
    #     export read_flow_from_list 
    #     export inspect_flow_data, inspect_doublers, strip_confn, strip_confn!, unify_mch, unify_mch!
    #     export dump_data_dic, read_data_dic, reconstruct
    #     export set_scale, topology, run_analysis
    #     export line, parabola, χ², uwfit
    #     export fmt

end
