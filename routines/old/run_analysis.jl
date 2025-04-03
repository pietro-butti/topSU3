using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics

include("routines.jl")


t_therm = Dict(
    "SuperCoarse" => 1,
    "Coarse-1"    => 1,
    "Coarse-2"    => 50,
    "Fine-1"      => 50,
    "Fine-2"      => 50,
    "SuperFine"   => 500 
)

##
for (ens,tth) in t_therm
# ens = "Fine-2"
# tth = 50

    file = "/Users/pietro/code/data_analysis/data/YM3/formatted/$ens.wilson.jld2"
    s8t0 = set_the_scale(ens,file,0.3,verbose=false, t_therm=tth)
    compute_tauint(ens, file, 5., t_therm=tth)
    a_fm = 0.144/s8t0 * sqrt(8)
    uwerr(a_fm)
    println("$ens: ", a_fm)
end

##
 

