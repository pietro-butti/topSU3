module LatKit
    using DataFrames, Pipe, StatsBase, ADerrors
    
    include("HiRep/HiRep.jl")
        using .HiRep
        export get_runtime, get_confn
        export get_plaquette, get_flow_data
        export read_spectrum, read_disconnected, uwdisc

end