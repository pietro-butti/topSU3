using topSU3, DataFrames, ADerrors, Plots
using JLD2, ArgParse, TOML, Serialization
using BDIO, ALPHAio, LsqFit
using LaTeXStrings, Statistics

using ADerrors
import ADerrors.err

params = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")
df = reconstruct("RESULTS/apr3",params)
ENSEMBLE_LIST = ["SuperCoarse","Coarse-1","Coarse-2","Fine-1","Fine-2"]

##

flw_dict = Dict()
for ens in ENSEMBLE_LIST
    flw_dict[ens] = Dict()
    for flow in ["wilson","lw","dbw2"]
        @info("Loading $ens $flow")
        @load params["ensembles"][ens][flow]["file"] flw_data
        flw_dict[ens][flow] = flw_data
    end
end



## ========================= PLOT FLOW CURVES ===========================

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
        size=(700,400)
        # legend=:bottomright 
    )

    flow = "wilson"
    for (i,ens) in enumerate(ENSEMBLE_LIST)
        fl = flw_dict[(ens,flow)]

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
        s8T0 = only(df[cond,:wf_scale])
        T0 = s8T0^2/8; uwerr(T0)

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
    hline!([0.3],color="gray",alpha=0.2,lw=3,ls=:dash,label="")

    display(plt)
## ======================================================================