using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics

volumes = Dict(
    "SuperCoarse" => 16,
    "Coarse-1"    => 20,
    "Coarse-2"    => 24,
    "Fine-1"      => 30,
)


scale = Dict()
a_fm  = Dict()
chi   = Dict()

infos = DataFrame(
    ens   = String[],
    scale = uwreal[],
    a_fm  = uwreal[],
    chi   = uwreal[]
)

for ens in ["SuperCoarse","Coarse-1","Coarse-2","Fine-1"]#,"Fine-2","SuperFine"]
# ens = "Coarse-1"    
    file = "/Users/pietro/code/data_analysis/data/YM3/formatted/$ens.wilson.jld2"
    @load file flow
    df = correct_mismatch(flow)
    uwf = uwflow(df, ens)
    
    # Extract scale
    t0 = tcut(uwf)(0.3)
    s = sqrt(8*t0)
    uwerr(s)

    # Lattice spacing
    a = 0.144/s * sqrt(8)
    uwerr(a)

    # topological suscepitibility
    tc = (volumes[ens]/4)^2 / 8
    topo = Qtop(df,tc)
    χ = uwreal(topo.qtop .^2 ,ens) / volumes[ens]^4
    uwerr(χ)

    push!(infos, (ens, s, a, χ))
end
    

##

a2 = infos.a_fm .^ 2
uwerr.(a2)

t₀²χ = (infos.scale .^2 / 8).^2 .* infos.chi
# t₀²χ = infos.chi
uwerr.(t₀²χ)

x = [x.mean for x in a2]
y   = [x.mean for x in t₀²χ]
erry = [x.err for x in t₀²χ]

scatter(x,y,yerr=erry, xlabel="a² [fm]", ylabel="χ", label="",legend=:topleft)