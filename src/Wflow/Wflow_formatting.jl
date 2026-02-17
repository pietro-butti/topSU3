function slice_at(df, t0)
    tflow = unique(df.flowt)
    it0 = argmin(abs.(tflow .- t0))
    return groupby(df, :flowt)[it0]
end


function find_mismatch(flow::DataFrame, idx1, idx2)
    mismatch = DataFrame(idx=[], miss=Vector[])

    g1 = unique(flow[:,idx1])
    g2 = unique(flow[:,idx2])

    @showprogress for i in g1 # cycle over confs
        ii = flow[flow[:,idx1] .== i,:][:,idx2]
        δ = setdiff(g2, ii)
        if length(δ)!==0
            push!(mismatch, (i,δ))
        end
    end
    
    rename!(mismatch, :idx => idx1)
    rename!(mismatch, :miss => idx2)

    return mismatch
end
find_mismatch(flow) = find_mismatch(flow, :itraj, :flowt)


function find_incomplete_flow(flow::DataFrame, trange::Vector; idx=:itraj)
    mismatch = DataFrame(aux=[])

    @showprogress for fl in groupby(flow, idx)
        trajn = fl[:,idx] |> unique |> only

        # check if :idx2 of fl is different from g2
        if fl.flowt != trange && length(fl.flowt)<length(trange)
            push!(mismatch, (trajn,))
        end
    end
    rename!(mismatch, :aux => idx)
    return mismatch
end
find_incomplete_flow(f,tr::StepRangeLen) = find_incomplete_flow(f,collect(tr))


function find_doublers(df::DataFrame; idx=:itraj)
    trajs = df[df.flowt .== 0.,idx]

    doublers = unique([i for (i,v) in countmap(trajs) if v==2])
    sort!(doublers)

    return doublers
end
