using Pkg; Pkg.activate(".")
using Revise
using topSU3, BDIO
using TOML, DataFrames, StatsBase


##

FILE_NAME = "./a12_b42703_L12.bdio"
run_name = string(split(split(FILE_NAME,"/")[end],".bdio")[1])


d1 = df_from_BDIO(FILE_NAME, "clover"; flow_type="Wilson")
d2 = df_from_BDIO(FILE_NAME, "qtop"; flow_type="Wilson")

innerjoin(d1,d2,on=[:confid,:flowt])