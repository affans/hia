using Parameters
using Match
using Distributions
using StatsBase
#using ParallelDataTransfer
using DataArrays, DataFrames
using ProgressMeter
using PmapProgressMeter
using JLD
#using Gadfly
#using Profile

include("parameters.jl")
include("datacollection.jl")
include("distributions.jl")
include("humans.jl")
include("vaccine.jl")
include("functions.jl")

function seed(simulationnumber::Int64, P::HiaParameters, cb)        
    ## simulationnumber is not needed for now. 
    ## savejld -- should we save the humans/DC data after the simulations have ended?
    ## loadjld -- should we load old humans/DC data     
    
    #wait(remotecall(info, 1, "simulation: $simulationnumber"))
    
    
    ## TODO: Print message, what are we doing?
    humans = Array{Human}(P.gridsize);    
    DC = DataCollection(P.simtime) #set P.vaccinetime = 0 to run without vaccine. 
    
    ## setup human grid   
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
    @inbounds for time = 1:P.simtime
        ## start of day.... get bins
        n = filter(x -> x.age < 365, humans)
        f = filter(x -> x.age >= 365 && x.age < 1460, humans)
        s = filter(x -> x.age >= 1460 && x.age < 3285, humans)    
        t = filter(x -> x.age >= 3285, humans)
     
        @inbounds for i in eachindex(humans)
            dailycontact(humans[i], P, ag1, ag2, ag3, ag4, n, f, s, t)
            tpp(humans[i], P)
            app(humans[i], P)
            update(humans[i], P, DC, time)          
        end
        cb(1)            
    end
    hf = string("./serial/hser", simulationnumber, ".jld")
    save(hf, "humans", humans, "DC", DC)
    return humans, DC
end


function pastthirty(simulationnumber, vaccineon, P::HiaParameters, cb)
    fn = string("./serial/hser", simulationnumber, ".jld")
    humans = load(fn)["humans"]     ## this gives a Array{Human} 

    DC = DataCollection(P.vaccinetime)     ## setup a new data collection instance for vaccine
    
    mmt, cmt = distribution_contact_transitions()  ## get the contact transmission matrix. 
    ag1 = Categorical(mmt[1, :])
    ag2 = Categorical(mmt[2, :])
    ag3 = Categorical(mmt[3, :])
    ag4 = Categorical(mmt[4, :])
    
    @inbounds for time = 1:P.vaccinetime
        ## start of day.... get bins
        n = filter(x -> x.age < 365, humans)
        f = filter(x -> x.age >= 365 && x.age < 1460, humans)
        s = filter(x -> x.age >= 1460 && x.age < 3285, humans)    
        t = filter(x -> x.age >= 3285, humans)
     
        @inbounds for i in eachindex(humans)
            dailycontact(humans[i], P, ag1, ag2, ag3, ag4, n, f, s, t)
            tpp(humans[i], P)
            app(humans[i], P)
            if vaccineon
                vcc(humans[i], P)    ## add vaccine specific code. 
            end
            update(humans[i], P, DC, time)          
        end
        cb(1)    
    end

    if vaccineon
        hf = string("./serial/vhser", simulationnumber, ".jld")
    else 
        hf = string("./serial/nvser", simulationnumber, ".jld")
    end
    save(hf, "humans", humans, "DC", DC)
    return humans, DC
end

    
#  P = HiaParameters(simtime = 100, gridsize = 100000, betaone = 1, betatwo = 1, betathree = 1, betafour = 1)
  #humans = Array{Human}(P.gridsize);
  #initialize(humans, P)
  #demographics(humans, P)
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
