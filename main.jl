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
include("distributions.jl")
include("humans.jl")
include("interaction.jl")
include("vaccine.jl")
include("functions.jl")


function testprogress()
    P = Progress(1000)
    for i = 1:1000
        next!(P)
        sleep(0.01)
    end
end


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
      ##  the order of operations:
    ##   - dailycontact, timeinstate++, age++
     #println("starting time loop distributions")
    for time = 1:P.simtime
        ## start of day.... get bins
        n = find(x -> x.age < 365, humans)
        f = find(x -> x.age >= 365 && x.age < 1460, humans)
        s = find(x -> x.age >= 1460 && x.age < 3285, humans)    
        t = find(x -> x.age >= 3285, humans)
        for x in humans
            dailycontact(x, P, humans, ag1, ag2, ag3, ag4, n, f, s, t)
            tpp(x, P)
            app(x, P)
            update(x, P, DC, time)
        end
        #next!(pg)
        #println(time)
        #cb == nothing ? next!(progress) : cb(1)  
        cb(1)
        #dailycontacttwo(humans, P, ag1, ag2, ag3, ag4)            
        #timeplusplus(humans, P)   
        #update(humans, P, DC, time)                              
    end
    #return humans, DC 
    return humans, DC
end

    
# a = map(x -> x.meetcnt, h)

 
# cuminv = cumsum(latavg/2)


# gg = map(x -> x.age, h)
# gg2 = map(x -> x.age, humans)
# plot(x=gg2, Geom.histogram)
# plot(x=1:365*10, y=symavg/2)

# symavg1 = symavg/2
# plot(x=365*3:365*7, y=symavg1[365*3:365*7])


#@time find(x -> x.age > 365, humans)