function read_flow_from_list(file_list)
    # Read all data in file list
    raw_data = get_flow_data.(file_list)

    # Assign file name to each flow
    for (i, f) in enumerate(file_list)
        name = split(f, "/")[end]
        raw_data[i][!,:from] = [name for _ in 1:size(raw_data[i],1)]
    end

    return vcat(raw_data...)
end

function inspect_flow_data(file_list)
    Logger = Dict()
    
    # Read all data in file list 
    flow = read_flow_from_list(file_list)

    # Find incomplete runs and strip
    Logger["Incomplete flow"] = find_mismatch(flow).itraj

    # Sort for conf number
    flow = sort(flow)
    
    # Check for doublers
    Logger["Doublers"] = find_doublers(flow)
    
    return Logger, flow
end

function inspect_doublers(df, dbl_list, keep_list)
    for dconf in dbl_list
        # For every doubler, find the corresponding doubling sources
        choice = df[df.itraj.==dconf .&& df.flowt .== 0.,:from]
    
        # If the source is not in the keep list, this should be empty
        fchoice = filter(x->x∈keep_list, choice)

        # Log a message
        if length(fchoice)==0
            println("For itraj=$dconf, the source is not in the keep list: choose between $choice")
        end
    end

    return 
end


function strip_confn(df, list)
    return filter(row -> row.itraj ∉ list, df)
end
function strip_confn!(df, list)
    return filter!(row -> row.itraj ∉ list, df)
end
function strip_confn(df, list, keep; key=:from)
    return filter(row -> row.itraj ∉ list || row[key]==keep, df)
end
function strip_confn(df, list, keep; key=:from)
    return filter!(row -> row.itraj ∉ list || row[key]==keep, df)
end
