

function get_plaquette(filename)
    df = DataFrame(itraj=Int[], plaq=Float64[])

    open(filename, "r") do f
        itraj = nothing
        for line in eachline(f)
            # Read configuration idx
            if startswith(line, "[MAIN][0]Trajectory") && contains(line,"generated")
                rgx = match(r"Trajectory #(\d+)", line)
                if rgx !== nothing
                    itraj = parse(Int, rgx[1])
                end
            
            # Read plaq data
            elseif startswith(line, "[MAIN][0]Plaquette")
                plq = match(r"\[MAIN\]\[0\]Plaquette (?<plaq>[-\d\.e\+]+)", line)
                if plq !== nothing
                    plaq = parse(Float64, plq[:plaq])
                    push!(df, (itraj, plaq))
                end
            end
        end
    end

    return df
end


function get_flow_data(filename)
    df = DataFrame(
        itraj  = Int[], 
        flowt  = Float64[], 
        t2Eplq = Float64[],
        t2Esym = Float64[],
        qtop   = Float64[]
    )

    itraj_rgx = r"\[IO\]\[0\]Configuration \[.*n(?P<itraj>[0-9]+)"
    flow_rgx = r"\[WILSONFLOW\]\[0\]WF \(t,E,t2\*E,Esym,t2\*Esym,TC\) = (?<flowt>[-\d\.e\+]+) (?<Eplq>[-\d\.e\+]+) (?<t2Eplq>[-\d\.e\+]+) (?<Eclv>[-\d\.e\+]+) (?<t2Eclv>[-\d\.e\+]+) (?<qtop>[-\d\.e\+]+)"

    open(filename, "r") do f
        itraj = nothing
        for line in eachline(f)
            # Read configuration idx
            if startswith(line, "[IO][0]Configuration")
                rgx = match(itraj_rgx, line)
                if rgx !== nothing
                    itraj = parse(Int, rgx[:itraj])
                end
            
            # Read flow data
            elseif startswith(line, "[WILSONFLOW][0]WF")
                flw = match(flow_rgx, line)
                if flw !== nothing
                    flowt  = parse(Float64, flw[:flowt] )
                    t2Eplq = parse(Float64, flw[:t2Eplq])
                    t2Eclv = parse(Float64, flw[:t2Eclv])
                    qtop   = parse(Float64, flw[:qtop]  )
                    
                    # Push to Data frame
                    push!(df, (itraj, flowt, t2Eplq, t2Eclv, qtop))
                end
            end
        end
    end

    return df
end

function get_flow_data(filename, flag)
    df = DataFrame(
        itraj  = Int[], 
        flowt  = Float64[], 
        t2Eplq = Float64[],
        t2Esym = Float64[],
        qtop   = Float64[],
        hpar   = Float64[],
        h2_avg = Float64[]
    )

    itraj_rgx = r"\[IO\]\[0\]Configuration \[.*n(?P<itraj>[0-9]+)"
    # flow_rgx = r"\[WILSONFLOW\]\[0\]WF \(t,E,t2\*E,Esym,t2\*Esym,TC,h,h2_avg\) = (?<flowt>[-\d\.e\+]+) (?<Eplq>[-\d\.e\+]+) (?<t2Eplq>[-\d\.e\+]+) (?<Eclv>[-\d\.e\+]+) (?<t2Eclv>[-\d\.e\+]+) (?<qtop>[-\d\.e\+]+)  (?<h>[-\d\.e\+]+)  (?<h2avg>[-\d\.e\+]+)"
    flow_rgx = r"\[WILSONFLOW\]\[0\]WF \(t,E,t2\*E,Esym,t2\*Esym,TC,h,h2_avg\) =\s+(?<flowt>[-\d\.e\+]+)\s+(?<Eplq>[-\d\.e\+]+)\s+(?<t2Eplq>[-\d\.e\+]+)\s+(?<Eclv>[-\d\.e\+]+)\s+(?<t2Eclv>[-\d\.e\+]+)\s+(?<qtop>[-\d\.e\+]+)\s+(?<h>[-\d\.e\+]+)\s+(?<h2_avg>[-\d\.e\+]+)"

    open(filename, "r") do f
        itraj = nothing
        for line in eachline(f)
            # Read configuration idx
            if startswith(line, "[IO][0]Configuration")
                rgx = match(itraj_rgx, line)
                if rgx !== nothing
                    itraj = parse(Int, rgx[:itraj])
                end
            
            # Read flow data
            elseif startswith(line, "[WILSONFLOW][0]WF")
                flw = match(flow_rgx, line)
                if flw !== nothing
                    flowt  = parse(Float64, flw[:flowt] )
                    t2Eplq = parse(Float64, flw[:t2Eplq])
                    t2Eclv = parse(Float64, flw[:t2Eclv])
                    qtop   = parse(Float64, flw[:qtop]  )
                    h      = parse(Float64, flw[:h])
                    h2_avg = parse(Float64, flw[:h2_avg])
                    
                    # Push to Data frame
                    push!(df, (itraj, flowt, t2Eplq, t2Eclv, qtop, h, h2_avg))
                end
            end
        end
    end

    return df
end


