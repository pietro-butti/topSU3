using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics

ENSEMBLE = "SuperCoarse"
FLOWTYPE = "lw"
PATH     = "/Users/pietro/code/data_analysis/data/YM3/formatted"
# TCUT     = (20/3)^2/8
TCUT     = 5.





## =========================================================================
path = PATH
ens = ENSEMBLE
flw = FLOWTYPE
Tcut = TCUT


# Load files


##
ps = []
for flw in ["wilson","lw","dbw2"]
    @info("Reading $flw")
    @load "$path/$ens.$flw.jld2" flw_data

    # Accumulation plot -----------------------------------------------
        acc = plot(
            xlabel="flow time",
            ylabel="Qtop [$flw]",
        )
        for flw in groupby(flw_data, :itraj)
            plot!(acc,
                flw.flowt,
                flw.qtop,
                label="",
                alpha=0.5,
                color="gray",
            )
        end

        vline!([Tcut], label="", ls=:dash, lw=2, color=:gray, alpha=0.7)

    # Histogram -----------------------------------------------------
        qtop = Qtop(flw_data,Tcut)
        q = qtop.qtop

        hst = stephist(
            q,
            bins=extrema(q)[1]:0.1:extrema(q)[end],
            orientation=:horizontal,
            yticks=false,
            xticks=false, 
            label="", 
            grid=false, 
            # ylim=extrema(q),
            xlims=(0,1),
            framestyle = :zerolines,
            normalize=true,
        )
        # xlims!(hst,0,nothing)

    # MC history ---------------------------------------------------
        mch = plot(
            ymirror=true,
            xlabel="conf #",
        )

        plot!(qtop.itraj,q, label="naive",xaxis=:shared)
        plot!(qtop.itraj,qtop.qtop_round, label="rounded",xaxis=:shared)

    push!(ps,[acc,hst,mch])
end
    
##

l = @layout [
    a{0.4w} b{0.2w} a{0.4w};
    a{0.4w} b{0.2w} a{0.4w};
    a{0.4w} b{0.2w} a{0.4w};
]
plt = plot(
    ps[1][1], ps[1][2], ps[1][3],
    ps[2][1], ps[2][2], ps[2][3],
    ps[3][1], ps[3][2], ps[3][3],
    layout=l, 
    link=:y, 
    ylim = extrema(q),
    size=(1000, 900),
    left_margin=10Plots.mm, bottom_margin=10Plots.mm,
)



title!(plt,ENSEMBLE)


display(plt)
