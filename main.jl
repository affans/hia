using Parameters
using Match
using Distributions
using StatsBase
using ParallelDataTransfer
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
include("costs.jl")

## HI - lots of information -  link: http://antimicrobe.org/b67.asp#t3a

function setuphumans(simid::Int64, P::HiaParameters, M::ModelParameters)
    ## This function sets up the humans either by initializing them as new humans, or by reading serial files.  
    if M.initializenew 
        humans = Array{Human{Int64}}(P.gridsize);    
        initialize(humans, P)     ## initializes the array
        demographics(humans, P)   ## applies demographics information
        tracking = insertrandom(humans, P, LAT) ## random latent human    
    else 
        fn = string(M.readloc, "seed", simid, ".jld")    
        humans = load(fn)["humans"]     ## this gives a Array{Human}         
    end
    #println(string("from inside setup: ", pointer_from_objref(humans)))
    return humans
end


function sim(simid::Int64, P::HiaParameters, M::ModelParameters, cb)
    humans = setuphumans(simid, P, M) ## get the humans
    DC = DataCollection(P.simtime) #set P.vaccinetime = 0 to run without vaccine. 
    C = CostCollection(P.gridsize, 8)  ## 8 because we have eight health states
    vaccineon = M.vaccineon
    ## get the distributions for contact strcuture to pass to dailycontact()
    #println("getting distributions")
    mmt, cmt = distribution_contact_transitions()  ## get the contact transmission matrix. 
    ag1 = Categorical(mmt[1, :])
    ag2 = Categorical(mmt[2, :])
    ag3 = Categorical(mmt[3, :])
    ag4 = Categorical(mmt[4, :])

    wait(remotecall(info, 1, "from simulation: $simid: vaccine status: $vaccineon"))
    wait(remotecall(info, 1, "from simulation: $simid: initialize new: $(M.initializenew)"))
    
    ## main time loop
    @inbounds for time = 1:P.simtime
        ## start of day.... get bins for jackson agegroup contact matrix
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
            update(humans[i], P, DC, C, time, humans)          
            #DC.system[i, time] = Int(humans[i].health)
        end
        cb(1)            
    end
    return humans, DC, C
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
