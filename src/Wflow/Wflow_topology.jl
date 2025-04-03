function find_optimal_alpha(df::DataFrame, tcut::Float64; alpha0=0.7)
    q = slice_at(df,tcut).qtop
    res = optimize( α->mean((α.*q .- round.(α.*q)).^2), [alpha0])
    return Optim.minimizer(res)
end

function Qtop(df::DataFrame, tcut::Float64; α=0.7)
    α = find_optimal_alpha(df,tcut)
    aux = slice_at(df,tcut)[:,[:itraj,:qtop]]
    aux.qtop_round = round.(α .* aux.qtop)
    return aux
end



function chi_from_theta!(df::DataFrame)
    θ = Series{Float64,3}((0.,1.,1.))
    df.chi_from_theta = map(x->x.c[2],exp.(-θ .* df.qtop))
    return nothing
end