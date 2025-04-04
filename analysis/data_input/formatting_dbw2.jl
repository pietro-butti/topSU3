using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics

name(path,ens,flw) = "$path/$ens.$flw.jld2"

PATH = "/Users/pietro/code/data_analysis/data/YM3/formatted"



## SuperCoarse ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.DBW2.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.DBW2.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.DBW2.ac.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.DBW2.ad.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    strip_confn!(df,[0])
    flw_data = df
    @save name(PATH,"SuperCoarse","dbw2") flw_data
## ===============================================================================    





## Coarse-1 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-1.DBW2.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-1.DBW2.ab.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    flw_data = strip_confn(df,[0,9980])
    @save name(PATH,"Coarse-1","dbw2") flw_data
## ===============================================================================    




## Coarse-2 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.DBW2.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.DBW2.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.DBW2.ac.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.DBW2.ad.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    flw_data = strip_confn(df,[0])
    # inspect_doublers(df, logg["Doublers"],[])
    # flw_data = filter(row->!(row.itraj∈logg["Doublers"] .&& row.from∉["Coarse-2.DBW2.ab.out_0"]),df)
##
    @save name(PATH,"Coarse-2","dbw2") flw_data
## ===============================================================================    






## Fine-1 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.DBW2.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.DBW2.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.DBW2.ac.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    # strip_confn!(df, logg["Incomplete flow"])
##
    # inspect_doublers(df, logg["Doublers"],["Fine-1.DBW2.ab.out_0"])
    # strip_confn!(df,logg["Doublers"],"Fine-1.DBW2.ab.out_0")
##
    flw_data = df
    @save name(PATH,"Fine-1","dbw2") flw_data
## ===============================================================================    




## Fine-2 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.DBW2.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.DBW2.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.DBW2.ad.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    flw_data = strip_confn(df, logg["Incomplete flow"])
##
    # inspect_doublers(df, logg["Doublers"],["Fine-1.DBW2.ab.out_0"])
    # strip_confn!(df,logg["Doublers"],"Fine-1.DBW2.ab.out_0")
##
    @save name(PATH,"Fine-2","dbw2") flw_data
## ===============================================================================    
