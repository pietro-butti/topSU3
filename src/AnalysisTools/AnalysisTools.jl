module AnalysisTools
    using DataFrames, ProgressMeter,ADerrors, Optim, Statistics, BDIO, JLD2, Serialization, ALPHAio, LsqFit
    using ..HiRep
    using ..Wflow

    include("AnalysisTools_formatting.jl")
        export read_flow_from_list 
        export inspect_flow_data, inspect_doublers
        export strip_confn, strip_confn!
        export unify_mch, unify_mch!

    include("AnalysisTools_bdio.jl")
        # export bdio_dump, bdio_read
        export dump_data_dic, read_data_dic, reconstruct
    
    include("AnalysisTools_routines.jl")
        export set_scale, topology, run_analysis
    
    include("AnalysisTools_fits.jl")
        export line, parabola, χ², uwfit


    function fmt(val, err; sig_figs::Int=2)
        err_rounded = round(err, sigdigits=sig_figs)  # Round error to the desired sig figs
        exponent = floor(Int, log10(err_rounded))  # Get order of magnitude of error
        val_rounded = round(val, digits=-exponent + (sig_figs - 1))  # Match value precision
        
        # Scale error to an integer
        err_scaled = round(err_rounded * 10^(-exponent + (sig_figs - 1))) |> Int  # Convert to integer
        
        return "$(val_rounded)($err_scaled)"
    end
    fmt(x::uwreal; sig_figs=2) = fmt(x.mean,x.err; sig_figs=sig_figs)
    export fmt

    
end