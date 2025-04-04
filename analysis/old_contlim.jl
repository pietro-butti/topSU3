using topSU3, DataFrames, ADerrors, Plots, JLD2, ArgParse, TOML, Serialization, BDIO, ALPHAio, LsqFit

import ADerrors.err

params = TOML.parsefile("/Users/pietro/code/data_analysis/topSU3/analysis/ensembles.toml")

df = reconstruct("RESULTS/wilson",params)
sort!(df, :ensemble, by = x -> findfirst(==(x), ["SuperCoarse","Coarse-1","Coarse-2","Fine-1","Fine-2"]))


##
c = 0.35


# Data
off = ["Fine-1","Fine-2"]


data = df[df.scheme .== c,:]
data = filter(x->x.ensemble∉off, data)

filter
xdata = data.a_fm.^2
# xdata = (1 ./ data.wf_scale) .^ 2
uwerr.(xdata)
ydata = (data.wf_scale.^2 ./ 8) .* data.χ
uwerr.(ydata)

# Fit 
model(x::Float64,p) = p[1]*x + p[2] 
model(x::Vector,p) = [model(el,p) for el in x]
model(x::Vector,p::Vector{uwreal}) = [model(el,p) for el in x]


fit = curve_fit(
    model,
    value.(xdata),
    value.(ydata),
    1. ./ err.(ydata).^2,
    [0.5,0.0006]
)


chisq(p, d) = sum((model(value.(xdata),p) .- d).^2 ./ err.(ydata).^2)
(fitp, csqexp) = fit_error(chisq, fit.param, ydata)


##
plt = plot()

# Plot
scatter!(plt,
    value.(xdata), 
    value.(ydata), 
    yerror=err.(ydata),
    label="wilson, c=$c"
)

xplot = 0:0.0001:maximum(value.(xdata))
yplot = model(collect(xplot),fitp)
uwerr.(yplot)

yup = value.(yplot) .+ err.(yplot)
ydw = value.(yplot) .- err.(yplot)
plot!(plt,xplot,yup, fillrange=ydw,alpha=0.2, label="")

display(plt)