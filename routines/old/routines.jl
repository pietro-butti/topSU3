using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics


function extract_flow(file; t_therm=nothing)
    # Read data
    @load file flow
    df = flow

    # Cut thermalization data
    if t_therm!==nothing
        conf0 = flow[flow.flowt .== 0.,:].itraj[t_therm]
        df = flow[flow.itraj .>= conf0, :]
    end

    # Correct measurements-conf mismatch
    return correct_mismatch(df)
end


function set_the_scale(
    ens_name, file, ref_scale; 
    obs=:t2Esym,
    t_therm=nothing,
    save_to=nothing,
    verbose=true
)
    df = extract_flow(file, t_therm=t_therm)
    uwf = uwflow(df, ens_name, obs=obs)
    
    # Extract scale
    t0 = tcut(uwf)(ref_scale)
    scale = sqrt(8*t0)

    # Γ-method
    uwerr(scale)

    # IO
    if verbose
        println("√(8T₀) = $scale")
    end

    if save_to!==nothing
        
    end

    return scale
end

function compute_tauint(
    ens_name, file, t_cut; 
    obs=:qtop_round,
    t_therm=nothing,
    save_to=nothing,
    verbose=true
)
    df = extract_flow(file, t_therm=t_therm)

    # Compute topological charge
    q = Qtop(df,t_cut)

    # evaluate uwreal variable and associated error
    uwq = uwreal(q[:,obs],ens_name)
    uwerr(uwq)

    return (taui(uwq,ens_name),dtaui(uwq,ens_name))
end


function compute_chi(
    ens_name, file, t_cut; 
    obs=:qtop_round,
    t_therm=nothing,
    save_to=nothing,
    verbose=true
)
    # Extract flow
    uwf = extract_flow(file; t_therm=t_therm)

    # Compute topological charge
    q = Qtop(flw,t_cut)

    # evaluate uwreal variable and associated error
    uwq = uwreal(q[:,obs],ens_name)
    uwerr(uwq)

    return (taui(uwq,ens),dtaui(uwq,ens))



end