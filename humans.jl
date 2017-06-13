# sets up the humans

type Human 
    ## disease parameters (modified in make() function)
    health::HEALTH     ## current health status
    swap::HEALTH       ## swap health status (works as "last status" also - see swap())
    path::Int8         ## the path they will take if they get sick
    inv::Bool          ## whether this human will become invasive
    plvl::Float32      ## protection level - 0 - 100% 
    ptime::Int32       ## how long this protection will last - maybe not needed 
    latcnt::Int32      ## how many times this person has become latent
    symcnt::Int32      ## how many times this person has become symptomatic
    invcnt::Int32      ## how many times this person has become invasive
    timeinstate::Int32 ## days spent in current health status   
    statetime::Int32   ## maximum amount of days spent in health status 
    ## contact structure and demographics
    age::Int32         ## age in days  - 365 days per year
    agegroup::Int32         ## agegroup - NOT the jackson contact matrix group.
    gender::GENDER     ## gender - 50% male/female
    meetcnt::Int32     ## total meet count. how many times this person has met someone else.    
    dailycontact::Int32## not needed ?? ## who this person meets on a daily basis. 
    ## vaccine
    pvaccine::Bool     ## if primary vaccine is turned on
    bvaccine::Bool     ## if booster vaccine is turned on
    dosesgiven::Int8   ## doses given, 1 2 3 after primary
    
    # constructor:: empty human - set defaults here
    ##  if changing, makesure to add/remove from reset() function
    Human( health = SUSC, 
           swap   = UNDEF, 
           path   = 0, 
           inv    = false,
           plvl   = 0,
           ptime  = 0,
           latcnt = 0,
           symcnt = 0,
           invcnt = 0,
           timeinstate = 0, statetime = typemax(Int32), 
           age = 0, agegroup = 0, gender = MALE,
           meetcnt = 0, dailycontact = 0,
           pvaccine = false, bvaccine = false, 
           dosesgiven = 0) = new(health, swap, path, inv, plvl, ptime, latcnt, symcnt, invcnt, timeinstate, statetime, age, agegroup, gender, meetcnt, dailycontact, pvaccine, bvaccine, dosesgiven) 
end



function initialize(h::Array{Human},P::HiaParameters)
    for i = 1:P.gridsize
        h[i] = Human()
    end
end

function demographics(h::Array{Human}, P::HiaParameters)
    age_cdf = distribution_age()
    for x in h
        rn = rand()
        ## the distribution is index 1-based so if we get index one below, this means they are under 1 years old
        ageyear = findfirst(x -> rn <= x, age_cdf)
        ageyear = ageyear - 1 ## since distribution is 1-based
        x.age =  rand(ageyear*365:ageyear*365 + 365)   ## convert to days
        x.agegroup = beta_agegroup(x.age)
        x.gender = rand() < 0.5 ? FEMALE : MALE
        x.plvl = protection(x)
    end
    return nothing
end

setswap(h::Human, swapto::HEALTH) =  h.swap = h.swap == UNDEF ? swapto : h.swap ## this function correctly sets the swap for a human.


function newborn(h::Human)
    ## make a human "born" by setting its values to defaults.
    h.health = SUSC
    h.swap   = UNDEF
    h.path   = 0 
    h.inv    = false
    h.plvl   = 0 #protection(h)
    h.ptime  = 0
    h.latcnt = 0
    h.symcnt = 0
    h.invcnt = 0
    h.timeinstate = 0
    h.statetime = typemax(Int32) 
    h.age = 0
    h.agegroup = beta_agegroup(0)
    h.gender = rand() < 0.5 ? FEMALE : MALE
    h.meetcnt = 0
    h.dailycontact = 0
    h.pvaccine = false 
    h.bvaccine = false 
    h.dosesgiven = 0
end

function app(h::Human, P::HiaParameters)
    ## update age, agegroup, natural death, and protectionlvl at 5 years old
    ## output: age++, might possibly die
    h.age += 1   ## increase age by one
    tage = h.age ## store as temp
    
    # check at a yearly level
    if mod(tage, 365) == 0
        # 5 year mark, if susceptible, booster protection will expire and person will go to 0.5 protection level
        if tage == 1825  
            h.plvl = protection(h)
        end
        # every year, recalculate agegroup
        h.agegroup = beta_agegroup(tage)
        
        # every year, check for death
        ageyears = Int(tage/365)
        if rand() < distribution_ageofdeath(ageyears, h.gender)
            newborn(h) 
        end
    end         
end

function tpp(x::Human, P::HiaParameters)
    ## this function checks if their timei in a state has expired.
    ## if so, set their swap.
    ## output: swap is set
    x.timeinstate += 1
    if x.timeinstate >= x.statetime && x.swap == UNDEF
        ## move their compartments
        @match Symbol(x.health) begin
            :SUSC => error("Hia model => A susceptible has expired - how?")
            :LAT  =>begin ## latency has expired, moving to either carriage or presymptomatic, depends on age
                        ## get their min/max carriage probs and whether they will go to invasive
                        minp, maxp, invp  = carriageprobs(x.path, P)  ## path should've been set when they became latent -- see swap() function. 
                        pc = rand()*(maxp - minp) + minp  ## randomly sample probability to carriage from range
                        x.swap = rand() < pc ? CAR : SYMP                            
                        # if the person is going to symptomatic, check if they will go to invasive
                        if x.swap == SYMP && x.invcnt == 0                       
                                x.inv = rand() < (1 - invp) ? true : false
                        end
                    end
            :CAR  => x.swap = REC
            :SYMP => x.swap = x.inv == true ? INV : REC        ## if going to invasive, check that
            :INV  => x.swap = REC
            :REC  => x.swap = SUSC
            _     => error("Hia => Health status not known to @match")
        end
    end
end


function dailycontact(x::Human, P::HiaParameters, h::Array{Human}, ag1, ag2, ag3, ag4, newborns, first, second, third)
    ## the daily contact with a human.. tranmission can occure
    rn = rand()
    ag = agegroup(x.age) ## determine the Jackson agegroup -- NOT THE SAME AS BETA AGEGROUP
    ## determine which row they are in for Jackson contact matrix       
    if ag == 1 
        dist = ag1
    elseif ag == 2 
        dist = ag2
    elseif ag == 3
        dist = ag3
    else 
        dist = ag4
    end  
    agtocontact = rand(dist) ## pick a random number from the distribution
    if agtocontact == 1
        randhuman = rand(newborns)
    elseif agtocontact == 2
        randhuman = rand(first)            
    elseif agtocontact == 3
        randhuman = rand(second)            
    elseif agtocontact == 4
        randhuman = rand(third)            
    else
        error("cant happen")
    end        
    ## at this point, human x and randhuman are going to contact each other.         
    ## check if transmission criteria is satisfied
    t = (x.health == SUSC || x.health == REC) && (h[randhuman].health == CAR || h[randhuman].health == SYMP || h[randhuman].health == PRE)
    y = (h[randhuman].health == SUSC || h[randhuman].health == REC) && (x.health == CAR || x.health == SYMP || x.health == PRE)  
    if t
        transmission(x, h[randhuman], P)
    elseif y 
        transmission(h[randhuman], x, P)
    end        
    x.dailycontact = randhuman
    x.meetcnt += 1
    h[randhuman].meetcnt += 1       
end

function protection(h::Human)
    ## this assigns the proper protection level - based on health, recovery, age, and vaccine combinations
    ## see notes for details, and parameter file for references.
    ## note- this assigns their protection level according to their CURRENT health and not their swap. 

    retval = 0.0 
    ## calculates protection level. protection only makes sense for recovered or 
    if h.health == REC 
        retval = 0.90  ## fixed protection level for recovery
    elseif h.health == SUSC 
        ## have they been sick? ie, are the coming into susceptible after recovery period
        if h.latcnt >= 1  
            ## they have been atleast sick once, so automatic 50% protection
            retval = 0.50
        else
            ## they have never been sick, check age and vaccine status
            if h.age < 1825 && !h.pvaccine  
                retval = 0.0  ## <5, unvaccincated
            elseif h.age < 1825 && h.dosesgiven == 1
                retval = 0.50 ## <5, after primary dose 1
            elseif h.age < 1825 && h.dosesgiven == 2 
                retval = 0.80 ## <5, after primary dose 2
            elseif h.age < 1825 && h.dosesgiven == 3 && h.bvaccine == false
                retval = 0.85
            elseif h.age < 1825 && h.dosesgiven == 3 && h.bvaccine == true 
                retval = rand()*(0.95 - 0.85)+0.85
            elseif h.age < 1825 
                track(h, 1)
                error("protection level not applied")
            else 
                retval = 0.5
            end
        end    
    else 
        ## they are in a compartment other than susc/rec.. no need for protection level
        retval = 0.0
    end
    return retval
end

function transmission(susc::Human, sick::Human, P::HiaParameters)
    ## computes the transmission probability using the baseline for a susc and a sick person. If person is carriage, there is an automatic 50% reduction in beta value.
    ## can only make the person swap to latent!
    
    ## error check
    if (sick.health != CAR) && (sick.health != SYMP) && (sick.health != PRE)
        error("Hia Model => transmission() -- sick person is not actually sick")
    end

    ## use the beta_agegroup information to extract the right beta value from parameters   
    beta = 0.0
    ag = sick.agegroup
    if ag == 1 
        beta = P.betaone
    elseif ag == 2
        beta = P.betatwo
    elseif ag == 3 || ag == 5
        beta = P.betathree
    elseif ag == 4
        beta = P.betafour
    else 
        error("Hia model => transmission() agegroup not correctly assigned")
    end

    ## if they are carriage or presymptomatic - apply a reduction (value set in parameters)
    trans = (sick.health == CAR || sick.health == PRE) ? beta*P.carriagereduction*(1 - susc.plvl) : beta*(1 - susc.plvl)
    if rand() < trans        
        setswap(susc, LAT)
    end
end

function swap(h::Human, P::HiaParameters)
    ## this function moves the human to a new compartment. 
    ## if moving to LATENT, calculate their path, and reset their invasive. 
    ## do not reset their invasive if NOT moving to latent.. this is because 
    ## invasive is set when moving to SYMP, so either set invasive = false when 
    ## they recover, OR (current solution) invasive = false when going to latent
    ## this function also updates their personal counters.

    ## ** see comment below on setting the variables (especially path) in correct order
    
    if h.swap == UNDEF
        return nothing
    end

    # common variables for all compartments    
    oldhealth = h.health ## need to pass into pathtaken()
    h.health = h.swap
    h.swap = UNDEF
    h.timeinstate = 0
    h.statetime = statetime(h.health, P)
    h.inv == h.health == LAT ? false : h.inv  ## reset invasive if they are going to latent.. when they expire out of latent and (possible) swap to symp, this property will be calculated again
    h.path = h.health == LAT ? pathtaken(oldhealth, h) : 0
    ## get their path, path depends on protection lvl  - so always update path BEFORE protection lvl. 
    ## ie, if the person is swappning to latent (ie, x.health = latent set above), protection() in the next line will return 0 for path taken.
    ## slight inconvenient "feature": when transferring from REC -> SUS (ie, health = SUS, oldhealth = REC), the pathtaken is "4".. however, the person's path isnt actually determined until he moves to latent
    h.plvl = protection(h) ## this will get a new protection level, based on the health we just set above

    ## update individual counters, and pathtaken/protection cases.
    if h.health == LAT   
        h.latcnt += 1
    elseif h.health == SYMP
        h.symcnt += 1
    elseif h.health == INV
        h.invcnt += 1    
    end
    return nothing
end


function update(x::Human, P::HiaParameters, DC::DataCollection, time)
    ## this function updates each humans
    ##  the order of operations:
    ##   - dailycontact, timeinstate++, age++
    ## this function counts incidence data and calls swap()

    ## unpack datacollection vectors  -- these are multidimensional vectors 
    @unpack lat, car, sym, inv, rec = DC 

    if x.swap != UNDEF
        ## collect our data
        if x.swap == LAT 
            lat[time, x.agegroup] += 1
        elseif x.swap == CAR
            car[time, x.agegroup] += 1
        elseif x.swap == SYMP
            sym[time, x.agegroup] += 1
        elseif x.swap == INV
            inv[time, x.agegroup] += 1
        elseif x.swap == REC
            rec[time, x.agegroup] += 1
        end  
        ## apply the swap function
        swap(x, P)  
    end
end


### OLD FUNCTIONS

function update_old(h::Array{Human}, P::HiaParameters, DC::DataCollection, time::Int64)
    ## this function updates the lattice.
    ##  the order of operations:
    ##   - dailycontact, timeinstate++, age++
    ## this function counts incidence data, increases age, and calculates death

    ## unpack datacollection vectors  -- these are multidimensional vectors 
    @unpack lat, car, sym, inv, rec = DC 
    
    ## go through each human
    for i in 1:P.gridsize 

        ## check for swaps     
        if h[i].swap != UNDEF
            ## collect our data
            if h[i].swap == LAT 
                lat[time, h[i].agegroup] += 1
            elseif h[i].swap == CAR
                car[time, h[i].agegroup] += 1
            elseif h[i].swap == SYMP
                sym[time, h[i].agegroup] += 1
            elseif h[i].swap == INV
                inv[time, h[i].agegroup] += 1
            elseif h[i].swap == REC
                rec[time, h[i].agegroup] += 1
            end    
            ## apply the swap function
            swap(h[i], P)
        end

        
    end
end



#deprecated
function timeplusplus(h::Array{Human}, P::HiaParameters)
    @simd for x in h ## for each human
        x.timeinstate += 1
        if x.timeinstate >= x.statetime && x.swap == UNDEF  #
            ## move their compartments
            @match Symbol(x.health) begin
                :SUSC => error("Hia model => A susceptible has expired - how?")
                :LAT  => begin ## latency has expired, moving to either carriage or presymptomatic, depends on age
                            ## get their min/max carriage probs and whether they will go to invasive
                            minp, maxp, invp  = carriageprobs(x.path, P)  ## path should've been set when they became latent -- see swap() function. 
                            pc = rand()*(maxp - minp) + minp  ## randomly sample probability to carriage from range
                            x.swap = rand() < pc ? CAR : SYMP                            
                            # if the person is going to symptomatic, check if they will go to invasive
                            if x.swap == SYMP && x.invcnt == 0                       
                                    x.inv = rand() < (1 - invp) ? true : false
                            end
                         end
                :CAR  => x.swap = REC
                :SYMP => x.swap = x.inv == true ? INV : REC        ## if going to invasive, check that
                :INV  => x.swap = REC
                :REC  => x.swap = SUSC
                _     => error("Hia => Health status not known to @match")
            end
        end
    end
end