using topSU3, DataFrames, ADerrors, Plots, JLD2


## --------------------------------------------------------------------
    files = [
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-1.to250.out_0",
        "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-1.out_0"
    ]
    
    flw1,flw2 = get_flow_data.(files)
    
    # take out last conf from flw1
    nflw1 = DataFrame(groupby(flw1,:itraj)[1:end-1])

    # stack dataframes
    flow = vcat(nflw1,flw2)
##
    @save "/Users/pietro/code/data_analysis/data/YM3/formatted/Coarse-1.wilson.jld2" flow
## --------------------------------------------------------------------
    





## --------------------------------------------------------------------
files = [
    "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.to250.out_0",
    "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.to630.out_0",
    "/Users/pietro/code/data_analysis/data/YM3/raw/Coarse-2.out_0"
]

flw1,flw2,flw3 = get_flow_data.(files)

# ##
# # eliminate 1980: flow computed only up to 18.36
# dflw2 = flw2[flw2.itraj .!== 12580,:]

##
# stack dataframes
flow = vcat(flw1,flw2,flw3)
@save "/Users/pietro/code/data_analysis/data/YM3/formatted/Coarse-2.wilson.jld2" flow
## --------------------------------------------------------------------






## --------------------------------------------------------------------
# files = [
#     "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.to250.out_0",
#     "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.out_0"
# ]
files = [
    "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.wilson.aa.out_0",
    "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-1.wilson.ab.out_0"
]



flw1,flw2 = get_flow_data.(files)



##
# nflw2 = DataFrame(groupby(flw2,:itraj)[2:end])

# # eliminate 1980: flow computed only up to 18.36
# flw2 = flw2[flw2.itraj .!== 12580,:]

# stack dataframes
flow = vcat(flw1,flw2)
##
@save "/Users/pietro/code/data_analysis/data/YM3/formatted/Fine-1.wilson.jld2" flow
## --------------------------------------------------------------------





## --------------------------------------------------------------------
files = [
    "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.to292.out_0",
    "/Users/pietro/code/data_analysis/data/YM3/raw/Fine-2.out_0"
]

flw1,flw2 = get_flow_data.(files)



##
# stack dataframes
flow = vcat(flw1,flw2)
##
@save "/Users/pietro/code/data_analysis/data/YM3/formatted/Fine-2.wilson.jld2" flow
## --------------------------------------------------------------------



## --------------------------------------------------------------------
files = [
    "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.to100.out_0",
    "/Users/pietro/code/data_analysis/data/YM3/raw/SuperCoarse.out_0"
]

flw1,flw2 = get_flow_data.(files)

# # eliminate 1980: flow computed only up to 1.96
# flw1 = flw1[flw1.itraj .!== 1980,:]


##
# stack dataframes
flow = vcat(flw1,flw2)
##
@save "/Users/pietro/code/data_analysis/data/YM3/formatted/SuperCoarse.wilson.jld2" flow
## --------------------------------------------------------------------




## --------------------------------------------------------------------
files = [
    "/Users/pietro/code/data_analysis/data/YM3/raw/SuperFine.out_0",
]

flow = get_flow_data(files[1])
##
@save "/Users/pietro/code/data_analysis/data/YM3/formatted/SuperFine.wilson.jld2" flow
## --------------------------------------------------------------------






