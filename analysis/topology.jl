include("common.jl")

## ================= UNIFY MC HISTORIES ====================

    ens = "Fine-2"
    df1 = flw_dict[ens]["wilson"]
    df2 = flw_dict[ens]["lw"]
    df3 = flw_dict[ens]["dbw2"]

    t1 = unique(df1.itraj)
    t2 = unique(df2.itraj)
    t3 = unique(df3.itraj)

    # Select starting conf
    filter!(x->x>=conf0[ens],t1)
    filter!(x->x>=conf0[ens],t2)
    filter!(x->x>=conf0[ens],t3)

    # Choosest the biggest step possible
    step    = gcd(gcd(t1),gcd(t2),gcd(t3))
    confmax = max(t1[end],t2[end],t3[end]) ÷ step

    it1 = Int64.(t1 .// step)
    it2 = Int64.(t2 .// step)
    it3 = Int64.(t3 .// step)

    q21 = uwreal(Qtop(df1, 10.).qtop .^2,ens,it1,confmax)
    q22 = uwreal(Qtop(df2, 10.).qtop .^2,ens,it2,confmax)
    q23 = uwreal(Qtop(df3, 10.).qtop .^2,ens,it3,confmax)
    uwerr(q2)

    r = rho(q2, ens)


## =================================================================



## =================================================================
chi = Dict()
T0  = Dict()
for ens in ENSEMBLE_LIST
    confmax = confrange[ens][end] 
    L       = params["ensembles"][ens]["size"]
    tq      = (L/4)^2 / 8  

    for ker in FLOW_LIST
        fl = flw_dict[ens][ker]
        fl.t2Eimp = 4/3 .* fl.t2Eplq - 1/3 .* fl.t2Esym
        t0 = uwscale(fl, 0.3, ens, obs=:t2Eimp, nmeas=confmax)
        T0[(ens,ker)] = t0

        q2 = uwreal( 
            Qtop(fl, tq).qtop .^2 , 
            ens, 
            confid(fl), 
            confrange[ens][end]
        )

        χ =  q2/L^4
        uwerr(χ)
        chi[(ens,ker)] = χ
    end
end
##

plt = plot()

for (i,ker) in enumerate(FLOW_LIST)
    χ  = [chi[(ens,ker)] for ens in ENSEMBLE_LIST]
    t0 = [ T0[(ens,"wilson")] for ens in ENSEMBLE_LIST]

    xdata = (1 ./ sqrt.(8. .* t0)) .+ ((i-1) * 0.003)
    ydata = χ .* t0 .^2
    uwerr.(xdata)
    uwerr.(ydata)

    scatter!(plt, value.(xdata), value.(ydata), yerror=err.(ydata),label=ker)
end

scatter!(plt, [0.], [0.000667], yerror=[0.000007])

display(plt)



## =================================================================












scale = reconstruct("RESULTS/apr4_scales.bdio"  , keys=["ensemble","flow_type","L","obs","ref"], values=["t0"])
top   = reconstruct("RESULTS/apr4_topology.bdio", keys=["ensemble","flow_type","L","scheme"], values=["χ","χround"])
