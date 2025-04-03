module HiRep
    using DataFrames

    function get_runtime(filename)
        ttime = 0.
        open(filename, "r") do f
            for line in eachline(f)
                if contains(line,"sec")
                    regex = r"\[([0-9\.]+) sec\]"
                    m = match(regex, line)
                    if m!==nothing
                        ttime += parse(Float64, m[1])
                    end
                end
            end
        end
        return ttime
    end

    function get_runtime(filename,check)
        ttime = 0.
        open(filename, "r") do f
            for line in eachline(f)
                if contains(line,check) && contains(line,"sec") 
                    regex = r"\[([0-9\.]+) sec\]"
                    m = match(regex, line)
                    if m!==nothing
                        ttime += parse(Float64, m[1])
                    end
                end
            end
        end
        return ttime
    end

    function get_confn(filename)
        counter = 0
        open(filename, "r") do f
            itraj_rgx = r"\[IO\]\[0\]Configuration \[.*n(?P<itraj>[0-9]+)"
            for line in eachline(f)
                if startswith(line, "[IO][0]Configuration")
                    rgx = match(itraj_rgx, line)
                    if rgx !== nothing
                        counter += 1
                    end
                end
            end
        end
        return counter
    end


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


    export get_runtime, get_confn
    export get_plaquette, get_flow_data

end