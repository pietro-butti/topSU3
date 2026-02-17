module IO
    using DataFrames

    # include("IO_HiRep.jl")
    # using .HiRep
    #     export get_runtime, get_confn
    #     export get_plaquette, get_flow_data

    include("IO_latticegpu.jl")
    using .latticegpu
        export get_flow_data, get_mc_history

end