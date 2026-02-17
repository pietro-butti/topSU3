module latticegpu
    using DataFrames

    # -------------------------------------------------------------------------
    # Internal helpers
    # -------------------------------------------------------------------------

    # Regex for the three-line HMC block:
    #   [ HMC ][ CONF 000101 ]: Delta H 5.029e-08
    #   [ HMC ][ CONF 101 ]: Config accepted : true
    #   [ HMC ][ CONF 000101 ] 1.829e+00 -7.011e-02 -2.032e+00
    const _DELTAH_RGX   = r"^\[ HMC \]\[ CONF \d+ \]: Delta H\s+(?<dH>[-\d\.e\+]+)"
    const _ACCEPTED_RGX = r"^\[ HMC \]\[ CONF (\d+) \]: Config accepted : (?<acc>true|false)"
    const _PLAQ_RGX     = r"^\[ HMC \]\[ CONF (?<conf>\d+) \]\s+(?<plaq>[-\d\.e\+]+)\s+(?<qtop>[-\d\.e\+]+)\s+(?<qrec>[-\d\.e\+]+)"

    # [ IO ][ CONF 101 ] conf saved in ./.cfg_n101
    const _IO_SAVE_RGX  = r"^\[ IO \]\[ CONF (?<conf>\d+) \] conf saved in"

    # [ FLOW ][ CONF 000101 ] t Eplt t2Eplq Eclv t2Eclv qtop qrec
    const _FLOW_RGX     = r"^\[ FLOW \]\[ CONF (?<conf>\d+) \]\s+" *
                          r"(?<time>[-\d\.e\+]+)\s+"  *
                          r"(?<Eplt>[-\d\.e\+]+)\s+"  *
                          r"(?<t2Eplq>[-\d\.e\+]+)\s+" *
                          r"(?<Eclv>[-\d\.e\+]+)\s+"  *
                          r"(?<t2Eclv>[-\d\.e\+]+)\s+" *
                          r"(?<qtop>[-\d\.e\+]+)\s+"  *
                          r"(?<qrec>[-\d\.e\+]+)"

    # -------------------------------------------------------------------------
    # get_mc_history
    # -------------------------------------------------------------------------
    """
        get_mc_history(filename) -> DataFrame

    Read the MC history from a LatticeRun `.out` file and return a DataFrame
    with one row per trajectory.

    Columns
    -------
    - `itraj`    :: Int     – trajectory index (zero-padded form, parsed from the
                              plaquette/data line for consistency)
    - `dH`       :: Float64 – Hamiltonian variation ΔH
    - `accepted` :: Bool    – whether the configuration was accepted by the HMC test
    - `plaq`     :: Float64 – average plaquette
    - `qtop`     :: Float64 – topological charge (clover)
    - `qrec`     :: Float64 – topological charge (rectangular)
    - `saved`    :: Bool    – true when a `[ IO ][ CONF … ] conf saved in …` line
                              was found for this trajectory
    """
    function get_mc_history(filename)
        df = DataFrame(
            itraj    = Int[],
            dH       = Float64[],
            accepted = Bool[],
            plaq     = Float64[],
            qtop     = Float64[],
            qrec     = Float64[],
            saved    = Bool[]
        )

        # Collect conf numbers that were written to disk
        saved_confs = Set{Int}()
        open(filename, "r") do f
            for line in eachline(f)
                m = match(_IO_SAVE_RGX, line)
                if m !== nothing
                    push!(saved_confs, parse(Int, m[:conf]))
                end
            end
        end

        # Parse the HMC block – three consecutive lines share the same itraj
        open(filename, "r") do f
            pending_dH       = nothing   # Float64 | nothing
            pending_accepted = nothing   # Bool    | nothing

            for line in eachline(f)

                # Line 1 of the block: Delta H
                if (m = match(_DELTAH_RGX, line)) !== nothing
                    pending_dH       = parse(Float64, m[:dH])
                    pending_accepted = nothing

                # Line 2 of the block: accepted / rejected
                elseif (m = match(_ACCEPTED_RGX, line)) !== nothing
                    pending_accepted = m[:acc] == "true"

                # Line 3 of the block: plaquette / qtop / qrec  →  emit row
                elseif (m = match(_PLAQ_RGX, line)) !== nothing
                    itraj = parse(Int, m[:conf])
                    plaq  = parse(Float64, m[:plaq])
                    qtop  = parse(Float64, m[:qtop])
                    qrec  = parse(Float64, m[:qrec])

                    # Safeguard: if either pending value is still nothing
                    # (e.g. first block was cut off), use sensible defaults
                    dH       = pending_dH       !== nothing ? pending_dH       : NaN
                    accepted = pending_accepted !== nothing ? pending_accepted  : false

                    push!(df, (
                        itraj,
                        dH,
                        accepted,
                        plaq,
                        qtop,
                        qrec,
                        itraj ∈ saved_confs
                    ))

                    # Reset pending state
                    pending_dH       = nothing
                    pending_accepted = nothing
                end
            end
        end

        return df
    end

    # -------------------------------------------------------------------------
    # get_flow_data
    # -------------------------------------------------------------------------
    """
        get_flow_data(filename) -> DataFrame

    Read gradient-flow measurements from a LatticeRun `.out` file and return
    a DataFrame with one row per (trajectory, flow-time) pair.

    Flow lines have the format (as printed in the file header):
        # time  Eplt  t2Eplq  Eclv  t2Eclv  qtop  qrec

    Columns returned
    ----------------
    - `itraj`   :: Int     – trajectory index
    - `time`    :: Float64 – gradient-flow time t
    - `t2Eplq`  :: Float64 – t2 × plaquette energy density
    - `t2Eclv`  :: Float64 – t2 × clover energy density
    - `qclv`    :: Float64 – topological charge from clover definition (qtop)
    - `qrec`    :: Float64 – topological charge from rectangular definition
    """
    function get_flow_data(filename)
        df = DataFrame(
            itraj  = Int[],
            time   = Float64[],
            t2Eplq = Float64[],
            t2Eclv = Float64[],
            qclv   = Float64[],
            qrec   = Float64[]
        )

        open(filename, "r") do f
            for line in eachline(f)
                m = match(_FLOW_RGX, line)
                if m !== nothing
                    push!(df, (
                        parse(Int,     m[:conf]  ),
                        parse(Float64, m[:time]  ),
                        parse(Float64, m[:t2Eplq]),
                        parse(Float64, m[:t2Eclv]),
                        parse(Float64, m[:qtop]  ),
                        parse(Float64, m[:qrec]  )
                    ))
                end
            end
        end

        return df
    end

    export get_mc_history, get_flow_data

end # module LatticeRun