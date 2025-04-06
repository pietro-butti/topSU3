# function bdio_dump(df; exclude=["a_fm","volume"], saveto="./", prefix="aux")
# # Create a copy of df: every uwreal (except `exclude`) 
# # will be substituted with a string with the BDIO file
# # in which the variable is saved

#     aux = DataFrame()

#     @assert isdir(saveto)

#     file = joinpath(saveto,"$prefix.bdio")
#     fb  = BDIO_open(file, "w", prefix)
#     uinfo = 1

#     # Cycle over all the columns of the df
#     for col in names(df)
#         # All uwreals
#         if isa(df[:,col],Vector{uwreal}) && col∉exclude

#             # Save uwreals 
#             for (key,value) in Dict(zip(df.ensemble, df[:,col]))
#                 write_uwreal(value,fb,uinfo)
#             end
            
#             # Save where they where stored and the corresponding user info
#             aux[:, col] = [(file,uinfo) for _ in 1:length(df[:,col])]
#             uinfo += 1

#         # Other data (just copy)
#         elseif col∉exclude
#             aux[:,col] = df[:,col]
#         end
#     end

#     sum_file = joinpath(saveto,"$prefix.jls") 
#     serialize(sum_file, aux)

#     BDIO_close!(fb)
# end


# function bdio_read(prefix)
# # Given a dumped jls files, read all the columns with uwreal record

#     cat = deserialize("$prefix.jls")
    
#     # Create dictionary and data bin
#     data = DataFrame() # bin to fill with uwreals
#     tmp = Dict() # uinfo => col_name
#     for col in names(cat)
#         if isa(cat[:,col],Vector{Tuple{String,Int64}})
#             cnt = unique([i[2] for i in cat[:,col]])[end]
#             tmp[cnt] = col
#             data[:,col] = Vector{uwreal}(undef,length(cat[:,col]))
#         else
#             data[:,col] = cat[:,col]
#         end
#     end

#     # Read dumped .bdio file
#     fb = BDIO_open("$prefix.bdio","r")
#     dt = Dict(k => uwreal[] for k in keys(tmp))
#     while BDIO_seek!(fb)
#         uinfo = BDIO_get_uinfo(fb)
#         if uinfo ∈ keys(tmp)
#             push!(dt[uinfo],read_uwreal(fb))
#         end
#     end
#     fb = BDIO_close!(fb)

#     # Fill data bin
#     for (uinfo,(col)) in tmp
#         data[:,col] .= dt[uinfo]
#     end

#     return data
# end



function dump_data_dic(df, name; keys=["ensemble","flow_type","scheme"], values=["wf_scale","χ","χround"], exclude=["a_fm","volume"])
    dic = Dict{String,Array{uwreal}}()
    for r in eachrow(df)
        kstr = join(vcat(r[keys]...),"_")
        dic[kstr] = vcat(r[values]...) 
    end

    io = IOBuffer()
    fb = ALPHAdobs_create("$name.bdio",io)
    ALPHAdobs_write(fb, dic)
    ALPHAdobs_close(fb)

    aux = DataFrame()
    for col in names(df)
        if !(eltype(df[:,col])<:uwreal) && col∉exclude 
            aux[:,col] = df[:,col]
        end
    end
    println(aux)
    serialize("$name.jls",aux)

    return
end


function read_data_dic(name)
    fb = BDIO_open(name, "r")

    count = 0
    res = Dict()
    while ALPHAdobs_next_p(fb)
        count+=1
        println("count:", count)
        
        d = ALPHAdobs_read_parameters(fb)
        nobs = d["nobs"]
        println("nobs: ", nobs)
        
        dims = d["dimensions"]
        println("dims: ", dims)
        
        sz = tuple(d["size"]...)
        println("size:", sz)
        
        ks = collect(d["keys"])
        res = ALPHAdobs_read_next(fb, size=sz, keys=ks)
    end
    BDIO_close!(fb)

    return res
end


function reconstruct(name,params)
    df1 = deserialize("$name.jls")
    
    aux = []
    for (kstr,obs) in sort(read_data_dic("$name.bdio"))
        ens,flw,csc = String.(split(kstr,"_")) 
        scheme = parse(Float64,csc)
        
        uwerr.(obs)
        wf_scale, χ, χround = obs

        a_fm = 0.144/wf_scale * sqrt(8)
        uwerr(a_fm)

        lsize = params["ensembles"][ens]["size"]
        volume = a_fm * lsize 
        uwerr(volume)

        push!(aux, 
            DataFrame(
                ensemble  = ens,
                flow_type = flw,
                L        = lsize,
                β        = params["ensembles"][ens]["beta"],
                volume   = volume,
                wf_scale = wf_scale,
                a_fm     = a_fm,
                scheme   = scheme,
                χ        = χ     ,
                χround   = χround
            )
        )
    end
    df2 = vcat(aux...)

    return innerjoin(df1,df2,on=intersect(names(df1),names(df2)))
end

function reconstruct(name; keys=["ensemble","flow_type","scheme"],values=["t0"])
    cols = vcat(keys,values)
    df = DataFrame([[] for _ in cols],cols)
    for (kstr,obs) in sort(read_data_dic(name))
        ks = String.(split(kstr,"_"))
        push!(df,(ks...,obs...))
    end
    return df
end