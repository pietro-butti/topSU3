module topSU3
    using BDIO, ADerrors
    using DataFrames, Plots, StatsBase

    dsum(x; dims) = dropdims(sum(x; dims); dims)
    dmean(x; dims) = dropdims(mean(x; dims); dims)
    export dsum, dmean

    include("IO/IO.jl")
    using .IO
        export BDIO_read_dict, BDIO_read_entry, df_from_BDIO

end
