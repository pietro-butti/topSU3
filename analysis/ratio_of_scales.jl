include("common.jl")






## ========================= PLOT FLOW CURVES ===========================
    flow = "wilson"

    colors = palette(:starrynight,5, rev=true)

    plt = plot(
        ylims=(0,0.5),
        xlims=(0.,15.),
        formatter=:latex,
        framestyle=:box, 
        xlabel=L"t/a^2", 
        ylabel=L" \langle t^2 E(t)\rangle", 
        guidefont=font(14),
        tickfont=font(12),
        legendfont=font(12),
        size=(700,400),
        left_margin=2Plots.mm
        # legend=:bottomright 
    )

    for (i,ens) in enumerate(ENSEMBLE_LIST)
        fl = flw_dict[ens][flow]

        f = fl[fl.flowt .< 20.,:]
        avg = combine(groupby(f,:flowt), :t2Esym => mean)
        plot!(plt,
            avg.flowt,avg.t2Esym_mean,
            color=colors[i],
            label=L"\texttt{%$ens}",
            linewidth=3.
        )

        avg = combine(groupby(f,:flowt), :t2Eplq => mean)
        plot!(plt,
            avg.flowt,avg.t2Eplq_mean,
            color=colors[i],
            label="",
            ls=:dash,
            alpha=0.3,
            lw=3.
        )

        cond = df.ensemble.==ens .&& 
            df.scheme.==0.3   .&& 
            df.flow_type.=="wilson"
        T0 = only(df[cond,:wf_scale])

        scatter!(plt,
            [value(T0)],[0.3],
            label="",
            color="white",
            markerstrokecolor=colors[i],
            markerstrokewidth=3,
            msize = 6,
            marker=:diamond,
            xerror=[err(T0)]
        )

        # for f in groupby(f,:itraj)
        #     plot!(plt,f.flowt,f.t2Esym,color=colors[i],label="",alpha=0.05)
        # end

    end
    hline!([0.3],color="gray",alpha=0.2,lw=3,ls=:dot,label="")

    display(plt)
    # savefig(plt,"PLOTS/flow_curves_$(flow)_all_curves.pdf")
## ======================================================================







## ======================================================================


scale = reconstruct("RESULTS/apr4_scales.bdio"  , keys=["ensemble","flow_type","L","obs","ref"], values=["t0"])
top   = reconstruct("RESULTS/apr4_topology.bdio", keys=["ensemble","flow_type","L","scheme"], values=["χ","χround"])
## ========================= SHORT/LONG RANGE RATIO ===========================
    sort!(scale,:L)

    OBS = "plq"

    cond =
        scale.flow_type.=="wilson" .&& 
        scale.obs.=="t2E$OBS" .&& 
        scale.ref.=="0.3"
    T0 = scale[cond,:t0]

    fitrange = Dict(
        "wilson" => 2:5,
        "lw"     => 2:5,
        "dbw2"   => 2:5,
    )

    colors2 = palette(:Spectral_4,rev=true)
    colors = palette(:starrynight,5, rev=true)
    cc = [colors[i] for i in 1:length(ENSEMBLE_LIST)]

    markers = Dict(
        "wilson" => :circle,
        "lw"     => :utriangle,
        "dbw2"   => :diamond,
    )


    pltl = plot(
        xlims=(0.,.27),
        formatter=:latex,
        framestyle=:box, 
        xlabel=L"a^2/t_0", 
        ylabel=L"t_0/t_1", 
        guidefont=font(14),
        tickfont=font(12),
        legendfont=font(12),
        # size=(700,400),
        # left_margin=2Plots.mm
    )

    pltr = plot(
        xlims=(0.,.27),
        ylims=(1.1,2.),
        formatter=:latex,
        framestyle=:box, 
        xlabel=L"a^2/t_0", 
        ylabel=L"t_0/t_2", 
        guidefont=font(14),
        tickfont=font(12),
        legendfont=font(12),
        legend=:topleft,
        # size=(700,400),
        # left_margin=2Plots.mm
    )

    for (i,ker) in enumerate(FLOW_LIST)

        cond =
            scale.flow_type.==ker .&& 
            scale.obs.=="t2Eimp"
            
        t0 = scale[cond .&& scale.ref.=="0.3" ,:t0]
        t1 = scale[cond .&& scale.ref.=="0.5" ,:t0]
        t2 = scale[cond .&& scale.ref.=="0.15",:t0]

        xdata = 1 ./ T0; uwerr.(xdata)

        # =======================================================
        long  = t0./t1; uwerr.(long )
        ydata = long

        # Fit
            rg = fitrange[ker]
            fitp,chi2,chiexp = uwfit(value.(xdata[rg]),ydata[rg])
            println(fitp)

        # Plot
            δ = std(value.(xdata))
            xplot = 0.:δ/10.:(maximum(value.(xdata[rg]))+δ/2)
            yplot = line(collect(xplot),fitp); uwerr.(yplot)
            plot!(pltl, 
                xplot, value.(yplot),
                label="",
                lw=3,ls=:dash,
                alpha=0.5,
                color=colors2[i]
            )

            scatter!(pltl,
                value.(xdata), value.(ydata), yerror=err.(ydata),
                label = "",
                markercolors=cc,
                # markerstrokecolor=:auto,
                markerstrokewidth=1.5,
                msize = 8,
                marker=markers[ker],
            )
        


        # =========================================================
        short = t0./t2; uwerr.(short)
        ydata = short

        # Fit
            fitp,chi2,chiexp = uwfit(value.(xdata[rg]),ydata[rg])

        # Plot
            δ = std(value.(xdata))
            xplot = 0.:δ/10.:(maximum(value.(xdata[rg]))+δ/2)
            yplot = line(collect(xplot),fitp); uwerr.(yplot)
            plot!(pltr, 
                xplot, value.(yplot),
                label="",
                lw=3,ls=:dash,
                alpha=0.5,
                color=colors2[i],
            )

            scatter!(pltr,
                value.(xdata), value.(ydata), yerror=err.(ydata),
                label = "",
                markercolors=cc,
                # markerstrokecolor=:auto,
                markerstrokewidth=1.5,
                msize = 8,
                marker=markers[ker],
            )

    end

    scatter!(pltr,[],[],label="Wilson",marker=markers["wilson"],color="white")
    scatter!(pltr,[],[],label="LW",marker=markers["lw"],color="white")
    scatter!(pltr,[],[],label="DBW2",marker=markers["dbw2"],color="white")

    plt = plot(
        pltl,pltr,
        layout = (1,2),
        size = (1000,400),
        left_margin   = 6Plots.mm,
        right_margin  = 2Plots.mm,
        bottom_margin = 6Plots.mm,
        top_margin    = 2Plots.mm,
        titles = ["Long range" "Short range"]
    )

    display(plt)
    savefig(plt,"PLOTS/ratio_of_scales_$OBS.pdf")




## ============================================================================





## ========================= DISCRETIZATION RATIO ===========================
    sort!(scale,:L)

    OBS = "imp"

    cond =
        scale.flow_type.=="wilson" .&& 
        scale.obs.=="t2E$OBS" .&& 
        scale.ref.=="0.3"
    T0 = scale[cond,:t0]

    fitrange = Dict(
        "wilson" => 2:5,
        "lw"     => 2:5,
        "dbw2"   => 2:5,
    )

    colors2 = palette(:Spectral_4,rev=true)
    colors = palette(:starrynight,5, rev=true)
    cc = [colors[i] for i in 1:length(ENSEMBLE_LIST)]

    markers = Dict(
        "wilson" => :circle,
        "lw"     => :utriangle,
        "dbw2"   => :diamond,
    )


    plt = plot(
        xlims=(0.,.27),
        # ylims=(0.,1.1),
        formatter=:latex,
        framestyle=:box, 
        xlabel=L"a^2/t_0", 
        # ylabel=L"t_0/t_0", 
        guidefont=font(14),
        tickfont=font(12),
        legendfont=font(12),
        # size=(700,400),
        # left_margin=2Plots.mm
    )

        cond =
            scale.obs.=="t2Eimp"  .&&
            scale.ref.=="0.3"
            
        t0w = scale[cond .&& scale.flow_type.=="wilson" ,:t0]
        t0d = scale[cond .&& scale.flow_type.=="dbw2"   ,:t0]
        t0l = scale[cond .&& scale.flow_type.=="lw"     ,:t0]

        xdata = 1 ./ T0; uwerr.(xdata)

        ydata1 = sqrt.(t0w./t0d); uwerr.(ydata1)
        ydata2 = sqrt.(t0w./t0l); uwerr.(ydata2)

        # =======================================================
        # # Fit
        #     rg = fitrange[ker]
        #     fitp,chi2,chiexp = uwfit(value.(xdata[rg]),ydata[rg])
        #     println(fitp)

        # Plot
            # δ = std(value.(xdata))
            # xplot = 0.:δ/10.:(maximum(value.(xdata[rg]))+δ/2)
            # yplot = line(collect(xplot),fitp); uwerr.(yplot)
            # plot!(pltl, 
            #     xplot, value.(yplot),
            #     label="",
            #     lw=3,ls=:dash,
            #     alpha=0.5,
            #     color=colors2[i]
            # )

            scatter!(plt,
                value.(xdata), value.(ydata1), yerror=err.(ydata1),
                markercolors=cc,
                markerstrokewidth=1.5,
                msize = 8,
                marker=:circle,
                label="Wilson/DBW2"
            )
        
            scatter!(plt,
                value.(xdata), value.(ydata2), yerror=err.(ydata2),
                markercolors=cc,
                markerstrokewidth=1.5,
                msize = 8,
                marker=:diamond,
                label="Wilson/LW"
            )
    


    #     # =========================================================
    #     short = t0./t2; uwerr.(short)
    #     ydata = short

    #     # Fit
    #         fitp,chi2,chiexp = uwfit(value.(xdata[rg]),ydata[rg])

    #     # Plot
    #         δ = std(value.(xdata))
    #         xplot = 0.:δ/10.:(maximum(value.(xdata[rg]))+δ/2)
    #         yplot = line(collect(xplot),fitp); uwerr.(yplot)
    #         plot!(pltr, 
    #             xplot, value.(yplot),
    #             label="",
    #             lw=3,ls=:dash,
    #             alpha=0.5,
    #             color=colors2[i],
    #         )

    #         scatter!(pltr,
    #             value.(xdata), value.(ydata), yerror=err.(ydata),
    #             label = "",
    #             markercolors=cc,
    #             # markerstrokecolor=:auto,
    #             markerstrokewidth=1.5,
    #             msize = 8,
    #             marker=markers[ker],
    #         )


    # scatter!(pltr,[],[],label="Wilson",marker=markers["wilson"],color="white")
    # scatter!(pltr,[],[],label="LW",marker=markers["lw"],color="white")
    # scatter!(pltr,[],[],label="DBW2",marker=markers["dbw2"],color="white")

    p = plot(
        plt,
        layout = (1,2),
        size = (1000,400),
        left_margin   = 6Plots.mm,
        right_margin  = 2Plots.mm,
        bottom_margin = 6Plots.mm,
        top_margin    = 2Plots.mm,
    )

    display(p)
    # savefig(p,"PLOTS/ratio_of_scales_$OBS.pdf")




## ============================================================================

