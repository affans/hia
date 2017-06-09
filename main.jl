using Parameters
using Match
using Distributions
using StatsBase
using DataArrays, DataFrames
using ProgressMeter
using Gadfly

#using PmapProgressMeter

include("parameters.jl")
include("distributions.jl")
include("humans.jl")
include("interaction.jl")
include("vaccine.jl")
include("functions.jl")

function main(simulationnumber::Int64, P::HiaParameters)
   
    DC = DataCollection(P.simtime)

    ##setup progress bar
    progress = Progress(P.simtime)

    ## setup human grid 
  
    humans = Array{Human}(P.gridsize);
    initialize(humans, P)
    demographics(humans, P)

    ## random latent human
    tracking = insertrandom(humans, P, LAT)

    ## main time loop - time unit is months
    for time = 1:P.simtime
        dailycontact(humans, P)            
        timeplusplus(humans, P)   
        update(humans, P, DC, time)
        next!(progress)
    end
    return humans, DC 
end
P = HiaParameters(simtime = 3650, gridsize = 100000)
latavg = zeros(Float64, P.simtime)
invavg = zeros(Float64, P.simtime)
symavg = zeros(Float64, P.simtime)
caravg = zeros(Float64, P.simtime)

for i = 1:2
    println("running sim $i")
    h, dc = main(1, P)
    @unpack lat, car, sym, inv, rec = dc ## unpack datacollection vectors
    latavg += lat 
    invavg += inv
    symavg += sym
    caravg += car
end

    
a = map(x -> x.meetcnt, h)

 
cuminv = cumsum(latavg/2)


gg = map(x -> x.age, h)
gg2 = map(x -> x.age, humans)
plot(x=gg2, Geom.histogram)
plot(x=1:365*10, y=symavg/2)

symavg1 = symavg/2
plot(x=365*3:365*7, y=symavg1[365*3:365*7])