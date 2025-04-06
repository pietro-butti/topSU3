module topSU3
    using DataFrames, Plots, ProgressMeter, Optim, Statistics, StatsBase, JLD2, Serialization
    using ADerrors, BDIO, FormalSeries, ALPHAio, LsqFit

    include("HiRep.jl")
    using .HiRep
        export get_runtime, get_confn 
        export get_plaquette, get_flow_data

    include("Wflow/Wflow.jl")
    using .Wflow
        export slice_at, find_mismatch, find_doublers, strip_confs!, process_flow_data
        export find_optimal_alpha, Qtop
        export uwflow, tcut, tbounds, uwscale, confid

    include("AnalysisTools/AnalysisTools.jl")
    using .AnalysisTools
        export read_flow_from_list 
        export inspect_flow_data, inspect_doublers, strip_confn, strip_confn!, unify_mch, unify_mch!
        export dump_data_dic, read_data_dic, reconstruct
        export set_scale, topology, run_analysis
        export line, parabola, χ², uwfit
        export fmt

    include("QPlots.jl")
    using .QPlots
        export accumulation_plot

end
