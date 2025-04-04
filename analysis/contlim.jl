using topSU3, DataFrames, ADerrors, Plots
using JLD2, ArgParse, TOML, Serialization
using BDIO, ALPHAio, LsqFit

using ADerrors
import ADerrors.err

params = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")

df = reconstruct("RESULTS/apr3",params)


##

plt = plot()

s8t0  = df[df.flow_type.=="wilson" .&& df.scheme.==0.3,:wf_scale]
afm = df[df.flow_type.=="wilson" .&& df.scheme.==0.3,:a_fm]


c = 0.35
for flow in ["wilson","lw","dbw2"]
    cond = df.scheme.==c .&& df.flow_type.==flow

    chi = df[cond,:χround]

    t0 = s8t0.^2  ./ 8; uwerr.(t0)
    # xdata = 1 ./ sqrt.(8 .* t0) 
    xdata = afm
    ydata = t0.^2 .* chi

    uwerr.(xdata)
    uwerr.(ydata)

    scatter!(plt,
        value.(xdata),
        value.(ydata),
        yerror = err.(ydata),
        label = flow
    )
end

display(plt)