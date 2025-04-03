using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics


enslist = ["SuperCoarse","Coarse-1","Coarse-2","Fine-1"]#,"Fine-2","SuperFine"]

plts = []

flw = Dict()
for ens in enslist
    file = "/Users/pietro/code/data_analysis/data/YM3/formatted/$ens.wilson.jld2"
    @load file flow
    flw[ens] = flow

    plt = plot()
    accumulation_plot(plt,flow)
    push!(plts,plt)
    # savefig(plt,"$ens.pdf")
end

plot(plts..., display=(2,3), size=(1000,600))

# display(pl)
##
plts = []
for ens in enslist
    qtop = Qtop(flw[ens],20.)
    p = plot(qtop.qtop,title=ens)
    push!(plts,p)
end

plot(plts..., display=(2,3), size=(1000,600))


##
ens = "SuperCoarse"
flow = flw[ens]
qtop = Qtop(flow,10.).qtop[50:end]


nn = "$(rand())"
uwq = uwreal(qtop,nn)
uwerr(uwq)
tt = taui(uwq,nn)

mch = plot(qtop, label="τᵢₙₜ = $(round(tt,digits=2))")
hst = histogram(qtop,bins=-9:0.1:9,orientation=:horizontal,yticks=false,xticks=false, label="", grid=false, xlim=(0,60))

plt = plot!(
    mch,hst,
    layout=grid(1,2,widths=[3/4,1/4]),
    link=:y, 
    ylim=(-9,9),
    size=(800,300),
    plot_title=ens
)

display(plt)
