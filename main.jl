using Parameters
using Match
using Distributions
using StatsBase
using ParallelDataTransfer
using DataArrays, DataFrames
using ProgressMeter
using PmapProgressMeter
using JLD2
using FileIO
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
        tracking = insertrandom(humans, P) ## random latent human    
    else 
        fn = string(M.readloc, "seed", simid, ".jld2")    
        humans = load(fn)["(rs[i])[1]"]     ## this gives a Array{Human}         
        ## the dictionary key is like this because of the way @save works from JLD2
    end
    return humans
end


function sim(simid::Int64, P::HiaParameters, M::ModelParameters, cb)
    ## model parameters
    vaccineon = M.vaccineon
    ttime = P.simtime
    
    humans = setuphumans(simid, P, M)    ## get the humans either as new initialization or read from file.
    
    ## data collection variables.
    #DC = DataCollection(P.simtime)
    costs = DataFrame(ID = Int64[], age = Int64[], systime = Int64[], health = Int64[], phys = Int64[], hosp = Int64[], med = Int64[], major = Int64[], minor = Int64[])
    dcc = DataFrame(systime = Int64[], ID = Int64[], age = Int64[], agegroup = Int64[], health = Int64[], sickfrom = Int64[],  invtype = Int64[], invdeath = Bool[], expectancy = Int64[])
    vac = DataFrame(systime = Int64[], ID = Int64[], age = Int64[], dose = Int64[])

    ## get the distributions for contact strcuture to pass to dailycontact()
    mmt, cmt = distribution_contact_transitions()  
    ag1 = Categorical(mmt[1, :])
    ag2 = Categorical(mmt[2, :])
    ag3 = Categorical(mmt[3, :])
    ag4 = Categorical(mmt[4, :])

    wait(remotecall(info, 1, "simulation: $simid is starting"))
    
    ## main time loop
    @inbounds for time = 1:ttime
        ## start of day.... get bins for jackson agegroup contact matrix
        n = filter(x -> x.age < 365, humans)
        f = filter(x -> x.age >= 365 && x.age < 1460, humans)
        s = filter(x -> x.age >= 1460 && x.age < 3285, humans)    
        t = filter(x -> x.age >= 3285, humans)
        @inbounds for i in eachindex(humans)
            ## run daily human functions - these can set a swap
            dailycontact(humans[i], P, ag1, ag2, ag3, ag4, n, f, s, t)
            tpp(humans[i], P)
            app(humans[i], P)
            
            ## run vaccine functions if applicable
            if vaccineon
                v = vcc(humans[i], P)    
                if v 
                    #vaccine was successful 
                    push!(vac, [time, humans[i].id, humans[i].age, humans[i].dosesgiven])
                end
            end
            
            ## if the swap got set from above functions -- update dataframes
            if humans[i].swap != UNDEF                
                swap(humans[i], P)                  
                        
                ## collect costs in dataframe, if the person is switching to symp or inv only
                if humans[i].health == SYMP || humans[i].health == INV
                    tmp = collect(collectcosts(humans[i], P, time))             
                    ttmp = vcat([humans[i].id, humans[i].age, time, Int(humans[i].health)], tmp) ## append additional system information.
                    push!(costs, ttmp )    
                end
                
                ## collect incidence data in dataframe 
                if humans[i].health != SUSC  ## dont add in data collection if the person has become susceptible again.
                    ## we potentially remove million of rows by not having this transition recorded.
                    ttmp = [time, humans[i].id, humans[i].age, humans[i].agegroup_beta, Int(humans[i].health), humans[i].sickfrom,
                            humans[i].invtype, humans[i].invdeath, humans[i].expectancy]
                    push!(dcc, ttmp)
                end                    
            end
        end
        cb(1)            
    end

    ## add simulation id to the data variables as columns
    dcc[:simid] = simid
    costs[:simid] = simid
    vac[:simid] = simid

    wait(remotecall(info, 1, "simulation: $simid finished"))
    #return humans, DC, costs, dcc
    return humans, costs, dcc, vac
    
end

