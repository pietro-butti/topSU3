module LatKit
    using DataFrames, Pipe, StatsBase, ADerrors
    
    include("HiRep/HiRep.jl")
        using .HiRep
        export get_runtime, get_confn
        export get_plaquette, get_flow_data
        export read_spectrum, read_disconnected, uwdisc
    
    include("Wflow.jl")
        using .Wflow
        export uwflow, tcut, tbounds, uwscale, confid
        export slice_at, find_optimal_alpha, Qtop

end