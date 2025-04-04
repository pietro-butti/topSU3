using topSU3, DataFrames, ADerrors, Plots, JLD2, ProgressMeter, Statistics

name(path,ens,flw) = "$path/$ens.$flw.jld2"

PATH = "/Users/pietro/code/data_analysis/data/YM3/formatted"


## SuperCoarse ===================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.to100.out_0"
    ]
    logg,df = inspect_flow_data(files)
##
    flw_data = strip_confn(df, logg["Incomplete flow"])
##
    @save name(PATH,"SuperCoarse","wilson") flw_data
## ===============================================================================






## Coarse-1 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-1.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-1.to250.out_0",
    ]
    logg,df = inspect_flow_data(files)
##
    inspect_doublers(df, logg["Doublers"],[])
##
    keep_list = ["Coarse-1.out_0"]
    flw_data = filter(row->!(row.itraj∈logg["Doublers"] .&& row.from∉keep_list),df)
##
    @save name(PATH,"Coarse-1","wilson") flw_data
## ===============================================================================    







## Coarse-2 ======================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.to250.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.to630.out_0",
    ]
    logg,df = inspect_flow_data(files)  
##
    inspect_doublers(df, logg["Doublers"],[])
##
    flw_data = strip_confn(df, logg["Incomplete flow"])
##
    @save name(PATH,"Coarse-2","wilson") flw_data
## ===============================================================================    


## Fine-1 ========================================================================
    files = [
        # "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.out_0",
        # "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.to250.out_0",
        # "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.out_0.mismatched",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.wilson.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.wilson.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.wilson.ac.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.wilson.ad.out_0",
    ]
    logg,df = inspect_flow_data(files)    
##
    inspect_doublers(df, logg["Doublers"],["Fine-1.wilson.aa.out_0","Fine-1.wilson.ab.out_0"])
##
    keep_list = ["Fine-1.wilson.aa.out_0","Fine-1.wilson.ab.out_0"]
    flw_data = filter(row->!(row.itraj∈logg["Doublers"] .&& row.from∉keep_list),df)
## Cut thermalization time
        flw_data = flw_data[flw_data.itraj .> 1000, :]
## Save data
    @save name(PATH,"Fine-1","wilson") flw_data
## ===============================================================================    




## Fine-2 ========================================================================
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.0.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.0.to292.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.to197200.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.wilson.aa.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.wilson.ab.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.wilson.ac.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.wilson.ad.out_0",
    ]
    logg,df = inspect_flow_data(files)    
##
    inspect_doublers(df, logg["Doublers"],[])
##
    keep_list = ["Fine-2.wilson.aa.out_0","Fine-2.wilson.ab.out_0","Fine-2.wilson.ac.out_0","Fine-2.wilson.ad.out_0"]
    inspect_doublers(df, logg["Doublers"],keep_list)
##
    flw_data = filter(row->!(row.itraj∈logg["Doublers"] .&& row.from∉keep_list),df)
## Cut thermalization time
    flw_data = flw_data[flw_data.itraj .> 1000, :]
## Save data
    @save name(PATH,"Fine-2","wilson") flw_data
## ===============================================================================    




## ===============================================================================    
## ===============================================================================    
## ===============================================================================    

