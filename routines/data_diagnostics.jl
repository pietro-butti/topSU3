using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics

ENSEMBLE = "Fine-1"
FLOWTYPE = "wilson"
PATH     = "/Users/pietro/code/data_analysis/data/YM3/formatted"
TCUT     = (30/3)^2/8
SAVETO   = nothing
# SAVETO   = "PLOTS/"





## =========================================================================
path = PATH
ens = ENSEMBLE
flw = FLOWTYPE
Tcut = TCUT


# Load files
@load "$path/$ens.$flw.jld2" flw_data
# flw_data = flw_data[flw_data.itraj .> 1000, :]


##
confn = flw_data[flw_data.flowt .== 0., :itraj]

global i = confn[end]
conf = []
while true
    if i∈confn
        push!(conf,i)
    end
    global i -= 140
    if i<0 break end
end

flw_data = filter(x->x.itraj∈conf, flw_data)


##
# Accumulation plot -----------------------------------------------
acc = plot(
    xlabel="flow time",
    ylabel="Qtop",
    # title=ens
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

plot!(qtop.itraj./20,q, label="naive")
plot!(qtop.itraj./20,qtop.qtop_round, label="rounded")

    
# Behold ----------------------------------------------------------
l = @layout [a{0.4w} b{0.2w} a{0.4w}]
plt = plot(
    acc, hst, mch,
    layout=l, 
    link=:y, 
    ylim = extrema(q),
    size=(1000, 300),
    left_margin=10Plots.mm, bottom_margin=10Plots.mm,
)

title!(plt,ENSEMBLE)


if SAVETO !==nothing
    savefig(plt,"$SAVETO/$ens.$flw.diagnosis.pdf")
else
    display(plt)
end
