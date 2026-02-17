# topSU3

This repository is a `julia` package to analyze data for the analysis of lattice artefacts on the topological susceptibility.


## Installation
Remember `BDIO.jl`



## Data production
Simulation data are produced using the `flowchi` branch of `LatticeGPU.jl` (link [here](https://github.com/pietro-butti/LatticeGPU.jl/tree/flowchi)) using `routines/run_HMC.jl` (or compatible routines).

```
usage: run_HMC.jl --L L [--Lx LX] -b BETA [--c0 C0] [--delta DELTA]
               [--nleaps NLEAPS] [--ntherm NTHERM] --ntraj NTRAJ
               [--epsilon EPSILON] [--nflow NFLOW]
               --flow-each FLOW-EACH [--saveto SAVETO]
               [--ens-name ENS-NAME] [--save-each SAVE-EACH]
               [--GPU GPU]
```
A minimal usage could be
```
julia run_HMC.jl --L 20 -b 6.15 --ntraj 10000 --flow-each 100 > OUTPUT.out
```


## Data Input
General simulation data for MC history can be obtained with `get_mc_history`
```
julia> get_mc_history("PATH_TO_FILE/OUTPUT.out")
10000×7 DataFrame
   Row │ itraj  dH           accepted  plaq     qtop        qrec        saved 
       │ Int64  Float64      Bool      Float64  Float64     Float64     Bool  
───────┼──────────────────────────────────────────────────────────────────────
     1 │   101   5.02914e-8      true  1.82934  -0.0701056   -2.03198    true
     2 │   102   3.63216e-8      true  1.82915   1.58897     -5.50346   false
     3 │   103  -6.70552e-8      true  1.82931   0.202538    -0.707511  false
     4 │   104   5.02914e-8      true  1.82866   1.45902      8.82084   false
     5 │   105  -1.24797e-7      true  1.82983   0.995066     4.2916    false
     6 │   106   7.26432e-8      true  1.82915   0.499579    -0.28078   false
     7 │   107   1.44355e-7      true  1.8275   -0.609872     1.78896   false
...
```

Wilson flow data can be read with `get_flow_data` as
```
julia> get_flow_data("PATH_TO_FILE/OUTPUT.out")
10100×6 DataFrame
   Row │ itraj  time     t2Eplq      t2Eclv       qclv        qrec     
       │ Int64  Float64  Float64     Float64      Float64     Float64  
───────┼───────────────────────────────────────────────────────────────
     1 │   101     0.0   0.0         0.0          -0.0701056  -2.03198
     2 │   101     0.01  0.00129383  0.00018979   -0.224733   -2.29038
     3 │   101     0.02  0.00475842  0.000739478  -0.346637   -2.54385
     4 │   101     0.03  0.00983018  0.00161589   -0.437678   -2.7828
     5 │   101     0.04  0.0160277   0.00278231   -0.500874   -2.99876
     6 │   101     0.05  0.0229488   0.0042       -0.53996    -3.18501
...
```

## Flow data analysis