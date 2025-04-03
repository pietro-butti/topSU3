using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics

ENSEMBLE = "Fine-1"
LSIZE    = 30
FLOWTYPE = "wilson"
PATH     = "/Users/pietro/code/data_analysis/data/YM3/formatted"
TCUT     = (LSIZE/2)^2/8
SAVETO   = nothing




## =========================================================================
path = PATH
ens = ENSEMBLE
flw = FLOWTYPE
Tcut = TCUT

# Load files
@load "$path/$ens.$flw.jld2" flw_data

# confn = flw_data[flw_data.flowt .== 0., :itraj]

# global i = confn[end]
# conf = []
# while true
#     if i∈confn
#         push!(conf,i)
#     end
#     global i -= 140
#     if i<0 break end
# end

# flw_data = filter(x->x.itraj∈conf, flw_data)



##


confn = confid(flw_data)



# Scale setting
t0 = uwscale(flw_data,0.3,ENSEMBLE)
scale = sqrt(8*t0)
uwerr(scale)

# fermi conversion
a_fm = 0.144/scale * sqrt(8)
uwerr(a_fm)

volume = (a_fm * LSIZE)^4
uwerr(volume)

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





## SUMMARY



df = DataFrame(
    ensemble = ENSEMBLE,
    L        = LSIZE,
    wf_scale = scale,
    a_fm     = a_fm,
    volume   = volume,
    τ        = tau,
    χ        = χ,
    χround   = χround
)

##

using Serialization
df = deserialize("routines/wilson.jls")