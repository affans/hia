using Parameters
using Match
using Distributions
using StatsBase
using DataArrays, DataFrames
#using ProgressMeter
#using PmapProgressMeter

include("distributions.jl")
include("parameters.jl")
include("humans.jl")
include("interaction.jl")
include("vaccine.jl")
include("functions.jl")


## encapusulate the following into a main function
P = HiaParameters(gridsize = 100000)
DC = DataCollection(P.simtime) ## initialize data collection 
humans = Array{Human}(P.gridsize);
initialize(humans, P)
demographics(humans, P)
tracking = insertrandom(humans, P, LAT)


@time dailycontact(humans, P)
@time timeplusplus(humans, P)
@time update(humans, P, DC, 1)
track(humans[tracking], tracking)
find(x -> x.health != SUSC, humans)
find(x -> x.health == INV, humans)


function main(simulationnumber::Int64)
    ## comment out after
    P = HiaParameters(gridsize = 100000)
    DC = DataCollection(P.simtime)


    ## setup human grid 
    humans = Array{Human}(P.gridsize);
    initialize(humans, P)
    demographics(humans, P)

    ## introduce random latent
    setswap(humans[rand(1:P.gridsize)], LAT)
    ## force the system to update
    update(humans, P, DC, 1)  ## this adds an extra latent into data collection


    ## main time loop - time unit is months
    for time = 1:P.simtime
        ageplusplus(humans, P) 
        timeplusplus(humans, P)   
        dailycontact(humans, P)    
        update(humans, P, DC, time)
    end
    return humans, DC 
end


