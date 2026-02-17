module IO
    using DataFrames

    include("IO_HiRep.jl")
    using .IO_HiRep
        export get_runtime, get_confn
        export get_plaquette, get_flow_data

end