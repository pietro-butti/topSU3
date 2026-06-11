
    read_itraj(line) = begin
        @pipe split(line)[2][2:end-1] |> split(_,"/") |> last |> split(_,"n") |> last |> parse(Int,_)
    end

    read_spectr_line(line) = begin
        rr = replace(line, r"^\[MAIN\]\[0\]conf #\d+ mass=[^\s]+ \S+ TRIPLET " => "") |> split
        name = rstrip(rr[1], '=')
        is_im = endswith(name, "_im")
        ig = is_im ? name[1:end-3] : name
        values = parse.(Float64, rr[2:end])
        ig, is_im, values
    end

    function read_spectrum(filename)
        df = DataFrame(
            itraj = Int[],
            t     = Int[],
            ig    = String[],
            cre   = Float64[],
            cim   = Float64[]
        )
        open(filename, "r") do f
            itraj = nothing
            pending_re = Dict{String, Vector{Float64}}()

            for line in eachline(f)
                if startswith(line, "[IO][0]Configuration ")
                    itraj = read_itraj(line)
                    empty!(pending_re)
                end

                if startswith(line, "[MAIN][0]conf")
                    ig, is_im, values = read_spectr_line(line)
                    if is_im
                        if haskey(pending_re, ig)
                            for (t, (cre, cim)) in enumerate(zip(pending_re[ig], values))
                                push!(df, (itraj, t - 1, ig, cre, cim))
                            end
                            delete!(pending_re, ig)
                        end
                    else
                        pending_re[ig] = values
                    end
                end
            end
        end
        return df
    end

    read_disc_line(line) = begin
        rr = replace(line, r"^\[CORR\]\[0\]\s*" => "") |> split
        it,ig,is = parse.(Int,rr[1:3])
        cre,cim = parse.(Float64,rr[4:5])
        (it,ig,is),(cre,cim)
    end

    function read_disconnected(filename)
        pattern = r"^\[CORR\]\[\d+\]\d+\s+(\d+)\s+(\d+)\s+([+-]?\d+(?:\.\d+)?e[+-]?\d+)\s+([+-]?\d+(?:\.\d+)?e[+-]?\d+)"

        df = DataFrame(
            confn  = Int[],
            itraj  = Int[],
            t     = Int[],
            ig    = Int[],
            is    = Int[],
            cre   = Float64[],
            cim   = Float64[]
        )
        open(filename, "r") do f
            confn = 0
            itraj = nothing

            for line in eachline(f)
                rgx = match(pattern,line)

                if startswith(line,"[IO][0]Configuration ")
                    confn += 1
                    itraj = read_itraj(line)
                end

                if !isnothing(rgx)
                    id, cdata = read_disc_line(line)
                    push!(df, (confn, itraj, id..., cdata...))
                end
                
            end
        end

        return df
    end

    function compute_disconnected(df; itraj=:itraj, ig=:ig, is=:is, t=:t, obs=:cre)
        combine(groupby(df, [itraj, ig])) do d

            # --- Self-join on time ------------------------------------------
            d1 = select(d, t, is => :is1, obs => :cre1)
            d2 = select(d, t, is => :is2, obs => :cre2)
        
            pairs = innerjoin(d1, d2, on = t)
            filter!(r -> r.is1 != r.is2, pairs)
        
            # --- For each pair (src1,src2), compute mean_[Δt](L1(t)*L2(t+Δt))
            per_pair = combine(groupby(pairs, [:is1, :is2])) do g
                dt = axes(g,1)
                DataFrame(
                    t   = dt,
                    val = [mean(g.cre1 .* circshift(g.cre2,-(d-1))) for d in dt]
                )
            end
        
            # --- Average over all (src1,src2) pairs with src1≠src2
            combine(groupby(per_pair, :t), :val => mean => :cdisc)
        end
    end


    function uwdisc(df, uwargs...; ig=:ig, dt=:t, obs=:cdisc)
        combine(groupby(df,[ig,dt])) do d
            DataFrame(
                ig   = first(d[:,ig]),
                dt   = first(d[:,dt]),
                disc = uwreal(d[:,obs][:],uwargs...)
            )
        end
    end

