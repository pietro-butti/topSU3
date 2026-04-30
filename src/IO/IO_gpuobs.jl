module gpuobs
    using BDIO, DataFrames


    dsum(x; dims) = dropdims(sum(x; dims); dims)
    dmean(x; dims) = dropdims(mean(x; dims); dims)

    """
    function BDIO_read_dict(io)

    Reads a dictionary from the current record of io. The entries of the dictionary must be split in the string as:

    "KEY1 = \\"VALUE1\\"\\nKEY2 = \\"VALUE2\\"\\n ....

    """
    function BDIO_read_dict(io)
        str = split.(split(BDIO_read_str(io),"\n")," = ")
        d = Dict{String,Any}()

        for i in 1:Int((length(str)-1))
            d[String(str[i][1])] = replace(String(str[i][2]),"\"" => "")
        end

        for k in keys(d)
            if occursin("[",d[k])
                str = replace.(replace.(split(d[k],","),"[" => ""),"]" => "")
                d[k] = [parse(Float64,str[i]) for i in 1:length(str)]
            end
        end

        return d
    end


    """
    function BDIO_read_entry(fname, d::Dict; dtype = Float64, duinfo = 8)

    Read the file fname and filters with the dictionary d. The dictionaries in the BDIO file must be in record duinfo, with value 8 by default
    and must have a MD5 checksum in the following record. The data must be two records after the dictionary.

    """
    function BDIO_read_entry(fname, d::Dict; dtype = Float64, duinfo = 8)
        fb = BDIO_open(fname,"r")
        mc = []
        d_out = nothing
        while BDIO_seek!(fb)
            if BDIO_get_uinfo(fb) == duinfo
                d_fb = BDIO_read_dict(fb)
                BDIO_seek!(fb)
                while BDIO_get_fmt(fb) == 0
                    BDIO_seek!(fb)
                end
                isd = true
                for k in keys(d)
                    if d[k] != d_fb[k]
                        isd = false
                    end
                end
                if isd
                    d_out = d_fb
                    foo = zeros(dtype,Int.(d_fb["size"])...)
                    BDIO_read(fb,foo)
                    push!(mc,foo)
                end
            end
        end
        BDIO_close!(fb)
        return mc, d_out
    end

    function df_from_BDIO(filename, obsid; flow_type="Wilson", name=nothing)
        isfile(filename) ? nothing : error("$filename not found...")

        @info("Reading $obsid data from $filename...")
        d = Dict{String, Any}("obs" => obsid, "flow_type"=>flow_type)
        obs,dict = BDIO_read_entry(filename,d);
        @info("...done!")

        t = dict["flow_times"]
        x = stack(obs)

        # Format data
        tmp = nothing
        if obsid=="clover"
            e   = dsum(x,dims=(2,3)) ./ size(x,2)
            tmp = t.^2 .* e
        elseif obsid ∈ ["qtop","qtop_rec"]
            tmp = dsum(x,dims=2)
        end

        # Collect into standard format DataFrame
        confid = collect(axes(tmp,2))
        df = DataFrame(
            confid = repeat(confid, inner=length(t)),
            flowt  = repeat(t, outer=length(confid)),
            obsid  = vec(tmp)
        )

        # Rename observable
        f = lowercase(first(flow_type))
        o = obsid=="clover" ? "t2E" : obsid=="qtop" ? "Qclv" : obsid=="qtop_rec" ? "Qrec" : ""
        rename!(df, :obsid => isnothing(name) ? "$f$o" : name)

        return df
    end

    export BDIO_read_dict, BDIO_read_entry, df_from_BDIO
end