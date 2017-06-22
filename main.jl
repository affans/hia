using Parameters
using Match
using Distributions
using StatsBase
using ParallelDataTransfer
using DataArrays, DataFrames
using ProgressMeter
using PmapProgressMeter

#using Gadfly
#using Profile

include("parameters.jl")
include("datacollection.jl")
include("distributions.jl")
include("humans.jl")
include("vaccine.jl")
include("functions.jl")

function main(simulationnumber::Int64, P::HiaParameters, cb)        
    ## check if we need to create an instance of a single progress bar
    ## cb is the callback function to update progress bar if running pmap progress bar    
    #progress = cb == nothing ? Progress(P.simtime, 1) : nothing
    
    #pg = Progress(P.simtime)
    #println("typeof progress: $(typeof(progress))")

    #P = HiaParameters(simtime = 3650, gridsize = 100000)
    DC = DataCollection(P.simtime)

    ## setup human grid   
    humans = Array{Human}(P.gridsize);
    initialize(humans, P)
    demographics(humans, P)

    ## random latent human
    tracking = insertrandom(humans, P, LAT)
    
    ## get the distributions for contact strcuture to pass to dailycontact()
    #println("getting distributions")
    mmt, cmt = distribution_contact_transitions()  ## get the contact transmission matrix. 
    ag1 = Categorical(mmt[1, :])
    ag2 = Categorical(mmt[2, :])
    ag3 = Categorical(mmt[3, :])
    ag4 = Categorical(mmt[4, :])


    ## main time loop
    for time = 1:P.simtime
        ## start of day.... get bins
        n = find(x -> x.age < 365, humans)
        f = find(x -> x.age >= 365 && x.age < 1460, humans)
        s = find(x -> x.age >= 1460 && x.age < 3285, humans)    
        t = find(x -> x.age >= 3285, humans)
        for i in eachindex(humans)
            dailycontact(humans[i], P, humans, ag1, ag2, ag3, ag4, n, f, s, t)
            tpp(humans[i], P)
            app(humans[i], P)
            update(humans[i], P, DC, time)          
        end
        cb(1)                        
    end
    return humans, DC
end

    
# P = HiaParameters(simtime = 100, gridsize = 100000, betaone = 1, betatwo = 1, betathree = 1, betafour = 1)
# humans = Array{Human}(P.gridsize);
# initialize(humans, P)
# demographics(humans, P)
#dailycontact(humans[hi], P, humans, ag1, ag2, ag3, ag4, n, f, s, t)
#find(x -> x.swap != UNDEF, humans)


#for i in eachindex(humans)
#   dailycontact(humans[i], P, humans, ag1, ag2, ag3, ag4, n, f, s, t)
#    tpp(humans[i], P)
#    app(humans[i], P)
#    @time update(humans[i], P, DC, time)                
    #println(i)
#end

#find(x -> x.health != SUSC, humans)
#track(humans[hi])
#   humans[1].health = INV
#   humans[1].invdeath = true

#   a = [statetime(humans[1], P) for i = 1:100000]
  
# a = map(x -> x.meetcnt, h)

 
# cuminv = cumsum(latavg/2)


# gg = map(x -> x.age, h)
# gg2 = map(x -> x.age, humans)
# plot(x=gg2, Geom.histogram)
# plot(x=1:365*10, y=symavg/2)

# symavg1 = symavg/2
# plot(x=365*3:365*7, y=symavg1[365*3:365*7])


#@time find(x -> x.age > 365, humans)
