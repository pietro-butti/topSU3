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
...
```

## Flow data analysis
Minimal flow data analysis include

- reference scale $t_0$ with `uwscale`
```
julia> df = get_flow_data("PATH_TO_FILE/OUTPUT.out");
julia> t0 = uwscale(df,0.3,"B1",time=:time,obs=:t2Eclv)
2.835825642952032 (Error not available... maybe run uwerr)
```

Some commments:
- Remember to specify the names of the `time` and `obs` columns in the flow data frame (like example)
- Last mandatory argument of the function is the `uwreal` ensemble specifying argument 