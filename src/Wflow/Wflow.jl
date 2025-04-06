"""
The basic input for this module is a `DataFrame` object that will be passed as argument to most of the functions in the modules. Such an object must look like:

```
2004002×5 DataFrame
     Row │ itraj  flowt    t2Eplq      t2Esym       qtop      
         │ Int64  Float64  Float64     Float64      Float64   
─────────┼────────────────────────────────────────────────────
       1 │    20     0.0   0.0         0.0          -0.733137
       2 │    20     0.01  0.00133921  0.000195178  -1.48943
       3 │    20     0.02  0.00493909  0.000762703  -1.71782
    ⋮    │   ⋮       ⋮         ⋮            ⋮           ⋮
 2004000 │ 20020    19.99  2.52216     2.46213      -1.92395
 2004001 │ 20020    20.0   2.52345     2.4634       -1.92398
 2004002 │ 20020    20.01  2.52473     2.46468      -1.92402
```

It can be obtained as the output of the function `HiRep.get_flow_data`.
"""
module Wflow
    using DataFrames, ProgressMeter,ADerrors, Optim, Statistics, StatsBase
    using FormalSeries
    
    include("Wflow_formatting.jl")
        export slice_at 
        export find_mismatch, find_doublers, strip_confs!

    include("Wflow_topology.jl")
        export find_optimal_alpha, Qtop
        export chi_from_theta!


    function uwflow(df::DataFrame, mcid::String; obs=:t2Esym)
        aux = DataFrame(flowt=Float64[], measure=[])
        for flw in groupby(df,:flowt)
            t = flw.flowt[1]
            t2E = uwreal(flw[:,obs],mcid)
            push!(aux, (t, t2E))
        end
    
        rename!(aux, :measure => obs)
        return aux
    end

    tcut(df; obs=:t2Esym) = sref -> begin
        y2 = df[df[:,obs] .> sref, :][1,obs]
        t2 = df[df[:,obs] .> sref, :][1,:flowt]

        y1 = df[df[:,obs] .< sref, :][end,obs]
        t1 = df[df[:,obs] .< sref, :][end,:flowt]

        m = (y2-y1)/(t2-t1)
        q = y1 - m*t1
        
        return (sref - q)/m
    end

    function tbounds(flw_data::DataFrame, sref::Float64; obs=:t2Esym)
        # Compute average values
        avg = combine(groupby(flw_data,:flowt), obs => mean)
        rename!(avg, names(avg)[end] => obs)
        
        # Compute t₀ with average
        scale = tcut(avg,obs=obs)(sref)
        
        # Find closest flow times in vector
        idx = searchsortedfirst(avg.flowt, scale)
        t1,t2 = avg.flowt[(idx-1):idx]

        return t1, t2
    end

    function confid(flw_data)
        trajs = unique(flw_data.itraj)
        trajs .-= trajs[1] # Subtract the first element
        trajs .+= trajs[2] # Add the second element to start form not zero
        # trajs = Int64.(trajs) .// gcd(trajs)
        return Int64.(trajs)
    end
    

    function uwscale(flw_data::DataFrame, sref::Float64, mcid; obs=:t2Esym, nmeas=-1)
        (t1,t2) = tbounds(flw_data,sref; obs=obs)      
        
        cfid = confid(flw_data)
        Nmeas  = nmeas<0 ? cfid[end] : nmeas

        E1 = flw_data[flw_data.flowt .== t1,obs]
        E2 = flw_data[flw_data.flowt .== t2,obs]

        y1 = uwreal(E1,mcid,cfid,Nmeas)
        y2 = uwreal(E2,mcid,cfid,Nmeas)

        m = (y2-y1)/(t2-t1)
        q = y1 - m*t1
        
        return (sref - q)/m
    end

    export uwflow, tcut, tbounds, uwscale, confid
    
end