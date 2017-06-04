using Parameters
using Match
using Parameters #module
using Distributions
using StatsBase
using DataArrays, DataFrames
#using ProgressMeter
#using PmapProgressMeter

include("distributions.jl")
include("parameters.jl")
include("humans.jl")
include("functions.jl")


## encapusulate the following into a main function
P = HiaParameters(gridsize = 100000)
humans = Array{Human}(P.gridsize);
initialize(humans, P)
demographics(humans, P)


function testmain()
    P = HiaParameters(gridsize = 100000)
    humans = Array{Human}(P.gridsize);
    initialize(humans, P)
    demographics(humans, P)
    transmission(humans[1], humans[2], P)
    setswap(humans[2], LAT)
    return humans
end

function main(simulationnumber::Int64)
    ## comment out after
    P = HiaParameters(gridsize = 100000)

    ## get the death distribution.
    pdm, pdf = distribution_ageofdeath()  ## distribution of deaths, do we need this every function?
    dprobs = [pdm, pdf]


    ## setup human grid 
    humans = Array{Human}(P.gridsize);
    initialize(humans, P)
    demographics(humans, P)

    ## main time loop - time unit is months
    for time = 1:P.simtime
        increase_age(humans, P, dprobs)        
    end
    for h in humans
        changestate(h, LAT, P)
    end    
    return humans 
end


