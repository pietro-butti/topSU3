

function set_scale(flw_data::DataFrame, ENSEMBLE, LSIZE; tcut=0.3, afm_factor=0.144, obs=:t2Esym)
    # Scale setting
    t0 = uwscale(flw_data,tcut,ENSEMBLE,obs=obs)
    scale = sqrt(8*t0)
    uwerr(scale)

    # fermi conversion
    a_fm = afm_factor/scale * sqrt(8)
    uwerr(a_fm)

    volume = (a_fm * LSIZE)^4
    uwerr(volume)

    return scale, a_fm, volume
end

function topology(flw_data::DataFrame, ENSEMBLE, LSIZE, TCUT)
    confn = confid(flw_data)

    # taui
    q = Qtop(flw_data,TCUT)
    uwq = uwreal(q.qtop,ENSEMBLE,confn,confn[end])
    uwerr(uwq)
    tau = (taui(uwq,ENSEMBLE),dtaui(uwq,ENSEMBLE))

    # compute χ
    χ = uwreal(q.qtop .^ 2,ENSEMBLE,confn,confn[end])
    χ /= LSIZE^4
    uwerr(χ)

    χround = uwreal(q.qtop_round .^ 2,ENSEMBLE,confn,confn[end])
    χround /= LSIZE^4
    uwerr(χround)

    return tau, χ, χround
end




function run_analysis(ensemble_list, flow_list, scheme_list, metap; verbose=true)
    params = metap["ensembles"]

    results = []
    for ens in ensemble_list
        lsize  = params[ens]["size"]
        for flow in flow_list
            # Read file
            if verbose
                println("Reading data for $ens...")
            end
            @load params[ens][flow]["file"] flw_data

            # Analysis ----------------------------
            if verbose
                println("Analyzing data for $ens...")
            end

            scale, a_fm, volume = set_scale(flw_data, ens, lsize)

            c_list = isempty(scheme_list) ? params[ens][flow]["scheme"] : scheme_list 
            for c in c_list
                if verbose
                    println("                       : scheme = $c...")
                end
                Tcut = (lsize*c)^2/8
                tau, χ, χround = topology(flw_data, ens, lsize, Tcut)
    
                df = DataFrame(
                    ensemble  = ens,
                    flow_type = flow,
                    L        = lsize,
                    wf_scale = scale,
                    a_fm     = a_fm,
                    volume   = volume,
                    scheme   = c,
                    t_cut    = Tcut,
                    τ        = tau,
                    χ        = χ,
                    χround   = χround
                )
                
                push!(results,df)
            end
        end
    end

    return vcat(results...)
end
