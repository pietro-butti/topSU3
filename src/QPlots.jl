module QPlots
    using DataFrames, Plots

    # =======================================================================
    # ======================= Topological charge distro =====================
    # =======================================================================
    function accumulation_plot(df::DataFrame; kwargs...)
        for flw in groupby(df, :itraj)
            plot!(flw.flowt,flw.qtop,label="",alpha=0.5,color="gray")
        end
    end
    function accumulation_plot(plt,df::DataFrame, kwargs...)
        for flw in groupby(df, :itraj)
            plot!(plt,flw.flowt,flw.qtop,label="",alpha=0.5,color="gray")
        end
    end
    # =======================================================================
    # =======================================================================
    # =======================================================================


    export accumulation_plot

end