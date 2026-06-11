module HiRep
    using DataFrames, Pipe, StatsBase, ADerrors

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

    export get_runtime, get_confn

    include("HiRep_flow.jl")
        export get_plaquette, get_flow_data

    include("HiRep_spectrum.jl")
        export read_spectrum
        export read_disconnected, compute_disconnected, uwdisc


end
