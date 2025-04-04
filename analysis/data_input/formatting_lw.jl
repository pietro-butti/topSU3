using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics

name(path,ens,flw) = "$path/$ens.$flw.jld2"

PATH = "/Users/pietro/code/data_analysis/data/YM3/formatted"


## SuperCoarse ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.LW.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.LW.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.LW.ac.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    strip_confn!(df,[0])
    flw_data = df
    @save name(PATH,"SuperCoarse","lw") flw_data
## ===============================================================================    




## Coarse-1 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-1.LW.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-1.LW.ab.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    strip_confn!(df,[0,5023])
    flw_data = df
    @save name(PATH,"Coarse-1","lw") flw_data
## ===============================================================================    




## Coarse-2 ======================================================================
    files = [
        # "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.LW.aa.to3880.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.LW.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.LW.ac.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.LW.ad.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    inspect_doublers(df, logg["Doublers"],[])
    flw_data = filter(row->!(row.itraj∈logg["Doublers"] .&& row.from∉["Coarse-2.LW.ab.out_0"]),df)
##
    @save name(PATH,"Coarse-2","lw") flw_data
## ===============================================================================    






## Fine-1 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.LW.to44100.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.LW.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.LW.ac.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.LW.ad.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    flw_data = strip_confn(df, logg["Incomplete flow"])
##
    inspect_doublers(flw_data, logg["Doublers"],["Fine-1.LW.ab.out_0"])
    strip_confn!(flw_data,logg["Doublers"],"Fine-1.LW.ab.out_0")
##
    @save name(PATH,"Fine-1","lw") flw_data
## ===============================================================================    




## Fine-2 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.LW.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.LW.ab.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    flw_data = strip_confn(df, logg["Incomplete flow"])
##
    # inspect_doublers(df, logg["Doublers"],["Fine-1.LW.ab.out_0"])
    # strip_confn!(df,logg["Doublers"],"Fine-1.LW.ab.out_0")
##
    @save name(PATH,"Fine-2","lw") flw_data
## ===============================================================================    
