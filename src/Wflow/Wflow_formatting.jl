# function slice_at(df, t0)
#     tflow = unique(df.flowt)
#     it0 = argmin(abs.(tflow .- t0))
#     return groupby(df, :flowt)[it0]
# end


# function find_mismatch(flow::DataFrame, idx1, idx2)
#     mismatch = DataFrame(idx=[], miss=Vector[])

#     g1 = unique(flow[:,idx1])
#     g2 = unique(flow[:,idx2])

#     @showprogress for i in g1 # cycle over confs
#         ii = flow[flow[:,idx1] .== i,:][:,idx2]
#         δ = setdiff(g2, ii)
#         if length(δ)!==0
#             push!(mismatch, (i,δ))
#         end
#     end
    
#     rename!(mismatch, :idx => idx1)
#     rename!(mismatch, :miss => idx2)

#     return mismatch
# end
# find_mismatch(flow) = find_mismatch(flow, :itraj, :flowt)


# function find_incomplete_flow(flow::DataFrame, trange::Vector; idx=:itraj)
#     mismatch = DataFrame(aux=[])

#     @showprogress for fl in groupby(flow, idx)
#         trajn = fl[:,idx] |> unique |> only

#         # check if :idx2 of fl is different from g2
#         if fl.flowt != trange && length(fl.flowt)<length(trange)
#             push!(mismatch, (trajn,))
#         end
#     end
#     rename!(mismatch, :aux => idx)
#     return mismatch
# end
# find_incomplete_flow(f,tr::StepRangeLen) = find_incomplete_flow(f,collect(tr))


# function find_doublers(df::DataFrame; idx=:itraj)
#     trajs = df[df.flowt .== 0.,idx]

#     doublers = unique([i for (i,v) in countmap(trajs) if v==2])
#     sort!(doublers)

#     return doublers
# end






"""
    slice_at(df, t0; time=:flowt)

Extracts a subset of the dataframe corresponding to the flow time closest to the 
specified target value t0.

# Arguments
- `df::DataFrame`: Input dataframe containing a flow time column
- `t0::Float64`: Target flow time value
- `time::Symbol`: Column name of the flow time (default: `:flowt`)

# Returns
- `SubDataFrame`: Subset of the input dataframe at the nearest flow time to t0
"""
function slice_at(df, t0; time=:flowt)
    # Extract unique flow time values
    tflow = unique(df[:, time])
    
    # Find index of flow time closest to target value
    it0 = argmin(abs.(tflow .- t0))
    
    # Return grouped data at the identified flow time
    return groupby(df, time)[it0]
end


"""
    find_mismatch(flow::DataFrame, idx1, idx2)

Identifies values in idx2 that are missing for each unique value in idx1, 
useful for finding incomplete data across different grouping variables.

# Arguments
- `flow::DataFrame`: Input dataframe
- `idx1::Symbol`: First index column name for grouping
- `idx2::Symbol`: Second index column name to check for completeness

# Returns
- `DataFrame`: Dataframe with columns `idx1` and `idx2`, where `idx2` contains 
  vectors of missing values for each `idx1`
"""
function find_mismatch(flow::DataFrame, idx1, idx2)
    # Initialize dataframe to store mismatches
    mismatch = DataFrame(idx=[], miss=Vector[])

    # Extract unique values from both index columns
    g1 = unique(flow[:, idx1])
    g2 = unique(flow[:, idx2])

    # Iterate over each unique value in first index
    @showprogress for i in g1
        # Extract all values of idx2 present for this idx1 value
        ii = flow[flow[:, idx1] .== i, :][:, idx2]
        
        # Find values in g2 that are NOT present for this idx1 value
        δ = setdiff(g2, ii)
        
        # Record mismatch if any values are missing
        if length(δ) !== 0
            push!(mismatch, (i, δ))
        end
    end
    
    # Rename columns to match original index names
    rename!(mismatch, :idx => idx1)
    rename!(mismatch, :miss => idx2)

    return mismatch
end

"""
    find_mismatch(flow; idx=:itraj, time=:flowt)

Convenience wrapper that checks for missing flow times across different trajectories.

# Arguments
- `flow::DataFrame`: Input dataframe with trajectory and flow time columns
- `idx::Symbol`: Column name containing trajectory identifiers (default: `:itraj`)
- `time::Symbol`: Column name of the flow time (default: `:flowt`)

# Returns
- `DataFrame`: Dataframe showing which flow times are missing for each trajectory
"""
find_mismatch(flow; idx=:itraj, time=:flowt) = find_mismatch(flow, idx, time)


"""
    find_incomplete_flow(flow::DataFrame, trange::Vector; idx=:itraj, time=:flowt)

Identifies trajectories that do not contain all flow time values specified in the 
target range.

# Arguments
- `flow::DataFrame`: Input dataframe containing flow data
- `trange::Vector`: Vector of expected flow time values
- `idx::Symbol`: Column name to group by (default: `:itraj`)
- `time::Symbol`: Column name of the flow time (default: `:flowt`)

# Returns
- `DataFrame`: Dataframe listing trajectory identifiers with incomplete flow time coverage
"""
function find_incomplete_flow(flow::DataFrame, trange::Vector; idx=:itraj, time=:flowt)
    # Initialize dataframe to store incomplete trajectories
    mismatch = DataFrame(aux=[])

    # Iterate over each group defined by idx column
    @showprogress for fl in groupby(flow, idx)
        # Extract the trajectory identifier (should be unique within group)
        trajn = fl[:, idx] |> unique |> only

        # Check if this trajectory has fewer flow times than the target range
        if fl[:, time] != trange && length(fl[:, time]) < length(trange)
            push!(mismatch, (trajn,))
        end
    end
    
    # Rename column to match index name
    rename!(mismatch, :aux => idx)
    
    return mismatch
end

"""
    find_incomplete_flow(f, tr::StepRangeLen; idx=:itraj, time=:flowt)

Convenience wrapper that converts a step range to a vector before calling 
the main incomplete flow detection function.

# Arguments
- `f::DataFrame`: Input dataframe containing flow data
- `tr::StepRangeLen`: Range object specifying expected flow time values
- `idx::Symbol`: Column name to group by (default: `:itraj`)
- `time::Symbol`: Column name of the flow time (default: `:flowt`)

# Returns
- `DataFrame`: Dataframe listing trajectory identifiers with incomplete flow time coverage
"""
find_incomplete_flow(f, tr::StepRangeLen; idx=:itraj, time=:flowt) = find_incomplete_flow(f, collect(tr); idx=idx, time=time)


"""
    find_doublers(df::DataFrame; idx=:itraj, time=:flowt)

Identifies trajectory identifiers that appear exactly twice at zero flow time,
indicating duplicate measurements.

# Arguments
- `df::DataFrame`: Input dataframe with flow data
- `idx::Symbol`: Column name containing trajectory identifiers (default: `:itraj`)
- `time::Symbol`: Column name of the flow time (default: `:flowt`)

# Returns
- `Vector`: Sorted vector of trajectory identifiers that appear exactly twice at time=0
"""
function find_doublers(df::DataFrame; idx=:itraj, time=:flowt)
    # Extract trajectory identifiers at zero flow time
    trajs = df[df[:, time] .== 0., idx]

    # Count occurrences and identify those appearing exactly twice
    doublers = unique([i for (i, v) in countmap(trajs) if v == 2])
    
    # Sort results for consistent output
    sort!(doublers)

    return doublers
end