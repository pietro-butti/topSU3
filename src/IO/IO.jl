module IO
    using DataFrames, ADerrors, BDIO

    include("IO_gpuobs.jl")
    using .gpuobs
        export BDIO_read_dict, BDIO_read_entry, df_from_BDIO

end