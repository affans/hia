## Haemophilus Influenza A, Agent Based Model for disease incidence 
## Developed by Affan Shoukat, PhD project

## import required packages
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
#using ProfileView

## include required files
include("parameters.jl")
include("datacollection.jl")
include("distributions.jl")
include("humans.jl")
include("vaccine.jl")
include("functions.jl")
include("costs.jl")


"""
    statetime(simid::Int64, P::HiaParameters, M::ModelParameters)

Sets up an array of humans, either as a fresh array or read from a .jld2 file given a simulation id. It creates an empty array of `P.gridsize`, initializes the array (ie. create Human() instances for each element), and runs `demographics(::Array{Human}, ::HiaParameters)`. `simid` is always required but is not used if setting up a fresh array of humans.
"""
function setuphumans(simid::Int64, P::HiaParameters, M::ModelParameters) 
    if M.initializenew 
        humans = Array{Human{Int64}}(P.gridsize);    
        initialize(humans, P)              ## initializes the array
        demographics(humans, P)            ## applies demographics information
        tracking = insertrandom(humans, P) ## random latent human    
    else 
        ## load humans from saved jld file. filename format: seed[id].jld2
        fn = string(M.readloc, "seed", simid, ".jld2")    
        humans = load(fn)["(rs[i])[1]"]     ## this gives a Array{Human}         
        ## the dictionary key is like this because of the way @save works from JLD2
    end
    return humans
end



"""
    sim(simid::Int64, P::HiaParameters, M::ModelParameters, cb::Function)

The main simulation entry point for Hia agent-based model. 
# Arguments
- `simid::Integer`: The simulation ID supplied manually. This needs to be unique for each simulation as it is appended on to the results datatables returned.
- `P::HiaParameters`: The Hia specific parameters.
- `M::ModelParameters`: The Model specific parameters.  
- `cb::Function`: is the callback function from `PmapProgressMeter` to update the progress bar. Simply provide `x -> 1` if not running from `pmap`. 

# Returns
  Returns a 4-tuple: (Human array at last time step, Cost datatable, incidence datatable, vaccine datatable)

  | simid | ID  | age | systime | health | phys | hosp | med | major | minor |
  |-------|-----|-----|---------|--------|------|------|-----|-------|-------|
  | ...   | ... | ... | ...     | ...    | ...  | ...  | ... | ...   | ...   |
"""
function sim(simid::Int64, P::HiaParameters, M::ModelParameters, cb)
    ## model parameters
    vaccineon = M.vaccineon
    ttime = P.simtime
    
    ## get the humans either as new initialization or read from file.
    humans = setuphumans(simid, P, M)    
    
    ## data collection datatables

    ## Costs
    # | simid | ID  | age | systime | health | phys | hosp | med | major | minor |
    # |-------|-----|-----|---------|--------|------|------|-----|-------|-------|
    # |       |     |     |         |        |      |      |     |       |       |

    ## DCC
    # | simid | systime | ID | age | agegroup | health | sickfrom | invtype | invdeath | expectancy | xpectancyreduced |
    # |-------|---------|----|-----|----------|--------|----------|---------|----------|------------|------------------|
    # |       |         |    |     |          |        |          |         |          |            |                  |

    ## Vaccination
    # | simid | systime | ID | age | dose |
    # |-------|---------|----|-----|------|
    # |       |         |    |     |      |
    
    costs = DataFrame(ID = Int64[], age = Int64[], systime = Int64[], health = Int64[], phys = Int64[], hosp = Int64[], med = Int64[], major = Int64[], minor = Int64[])
    dcc = DataFrame(systime = Int64[], ID = Int64[], age = Int64[], agegroup = Int64[], health = Int64[], sickfrom = Int64[],  invtype = Int64[], invdeath = Bool[], expectancy = Int64[], expectancyreduced = Int64[])
    vac = DataFrame(systime = Int64[], ID = Int64[], age = Int64[], dose = Int64[])

    ## get the probabilities for contact strcuture to pass to dailycontact()
    mmt, cmt = distribution_contact_transitions()  
    ## using the probabilties, generate the categorical variables
    ag1 = Categorical(mmt[1, :])
    ag2 = Categorical(mmt[2, :])
    ag3 = Categorical(mmt[3, :])
    ag4 = Categorical(mmt[4, :])

    #wait(remotecall(info, 1, "simulation: $simid is starting"))
        
    ## main time loop
    @inbounds for time = 1:ttime
        ## start of day.... split humans into bins for use with jackson agegroup contact matrix
        n = filter(x -> x.age < 365, humans)
        f = filter(x -> x.age >= 365 && x.age < 1460, humans)
        s = filter(x -> x.age >= 1460 && x.age < 3285, humans)    
        t = filter(x -> x.age >= 3285, humans)
        ## go through each human
        @inbounds for i in eachindex(humans)
            ## run daily human functions - these can set a swap
            dailycontact(humans[i], P, ag1, ag2, ag3, ag4, n, f, s, t)
            tpp(humans[i], P)
            app(humans[i], P)
            
            ## run vaccine functions if applicable
            if vaccineon
                v = vcc(humans[i], P)    
                if v 
                    #vaccine was successful, update the results data table
                    push!(vac, [time, humans[i].id, humans[i].age, humans[i].dosesgiven])
                end
            end
            
            ## if the swap got set from above functions -- update dataframes
            if humans[i].swap != UNDEF                
                swap(humans[i], P)                  
                
                # if the person is switching to sympomatic or invasive, then they have a cost associated
                #   collect these costs in dataframe.
                if humans[i].health == SYMP || humans[i].health == INV
                    tmp = collect(collectcosts(humans[i], P, time))             
                    ttmp = vcat([humans[i].id, humans[i].age, time, Int(humans[i].health)], tmp) ## append additional system information.
                    push!(costs, ttmp )    
                end
                
                ## collect incidence data in dataframe 
                if humans[i].health != SUSC  ## dont add in data collection if the person has become susceptible again.
                    ## we potentially remove million of rows by not having this transition recorded.
                    ttmp = [time, humans[i].id, humans[i].age, humans[i].agegroup_beta, Int(humans[i].health), humans[i].sickfrom,
                            humans[i].invtype, humans[i].invdeath, humans[i].expectancy, humans[i].expectancyreduced]
                    push!(dcc, ttmp)
                end                    
            end
        end
        cb(1)            
    end

    ## add simulation id to the data variables as a separate column.
    dcc[:simid] = simid
    costs[:simid] = simid
    vac[:simid] = simid

    #return humans, DC, costs, dcc
    return humans, costs, dcc, vac
    
end



function benchmark()
    # Setup code goes here.
    P = HiaParameters(simtime = 365*5)
    M = ModelParameters(numofsims = 2, initializenew = true, vaccineon=false, savejld=true)
    
    # Run once, to force compilation.
    println("======================= First run:")
    @time a = sim(1, P, M, x->1);
    
    # Run a second time, with profiling.
    println("\n\n======================= Second run:")
    Profile.init(delay=0.01)
    Profile.clear()
    #clear_malloc_data()
    @profile @time b = sim(1, P, M, x->1);
    #ProfileView.view()
    # Write profile results to profile.bin.
    r = Profile.retrieve()
    f = open("profile.bin", "w")
    serialize(f, r)
    close(f)
  end