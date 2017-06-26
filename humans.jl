# sets up the humans

type Human 
    ## disease parameters (modified in make() function)
    health::HEALTH     ## current health status
    swap::HEALTH       ## swap health status (works as "last status" also - see swap())
    path::Int8         ## the path they will take if they get sick
    invtype::INVTYPE   ## if they become invasive, what kind of invasive disease?
    invdeath::Bool     ## whether this human is invasive and will die
    plvl::Float32      ## protection level - 0 - 100% 
    latcnt::Int32      ## how many times this person has become latent
    symcnt::Int32      ## how many times this person has become symptomatic
    invcnt::Int32      ## how many times this person has become invasive
    timeinstate::Int32 ## days spent in current health status   
    statetime::Int32   ## maximum amount of days spent in health status 
    ## contact structure and demographics
    age::Int32         ## age in days  - 365 days per year
    agegroup_beta::Int32         ## - NOT the jackson contact matrix group.
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
           invtype = NOINV, 
           invdeath = false,
           plvl   = 0,
           latcnt = 0,
           symcnt = 0,
           invcnt = 0,
           timeinstate = 0, statetime = typemax(Int32), 
           age = 0, agegroup_beta = 0, gender = MALE,
           meetcnt = 0, dailycontact = 0,
           pvaccine = false, bvaccine = false, 
           dosesgiven = 0) = new(health, swap, path, invtype, invdeath, plvl, latcnt, symcnt, invcnt, timeinstate, statetime, age, agegroup_beta, gender, meetcnt, dailycontact, pvaccine, bvaccine, dosesgiven) 
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
        x.agegroup_beta = beta_agegroup(x.age)
        x.gender = rand() < 0.5 ? FEMALE : MALE
        x.plvl = protection(x)
    end
    return nothing
end


function newborn(h::Human)
    ## make a human "born" by setting its values to defaults.
    h.health = SUSC
    h.swap   = UNDEF
    h.path   = 0   
    h.invtype = NOINV
    h.invdeath = false
    h.plvl   = 0 #protection(h)
    h.latcnt = 0
    h.symcnt = 0
    h.invcnt = 0
    h.timeinstate = 0
    h.statetime = typemax(Int32) 
    h.age = 0
    h.agegroup_beta = beta_agegroup(0)
    h.gender = rand() < 0.5 ? FEMALE : MALE
    h.meetcnt = 0
    h.dailycontact = 0   ## deprecated, no one cares. 
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
        h.agegroup_beta = beta_agegroup(tage)
        
        # every year, check for death
        ageyears = Int(tage/365)
        if rand() < distribution_ageofdeath(ageyears, h.gender)
            h.swap = DEAD  ##swap to natural death
            ##newborn(h) 
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
            :LAT  =>begin ## latency has expired, moving to either carriage or symptomatic or invasive, depends on age
                        ## get their min/max carriage probs and whether they will go to invasive
                        minp, maxp, invp  = carriageprobs(x.path, P)  ## path should've been set when they became latent -- see swap() function. 
                        pc = rand()*(maxp - minp) + minp  ## randomly sample probability to carriage from range
                        if rand() < pc 
                            x.swap = CAR  ## going to carriage
                        else
                            ## going to symptomatic or invasive
                            if rand() < (1 - invp) && x.invcnt == 0
                                x.swap = INV
                            else 
                                x.swap = SYMP
                            end
                        end 
                    end
            :CAR  => x.swap = REC
            :SYMP => x.swap = REC
            :INV  => 
                    begin ## person is coming out of invasive
                        x.invtype = NOINV  ## if the swap is dead, this gets reset anyways. 
                        ## if invdeath was on.. they will die..     
                        x.swap = x.invdeath == true ? DEAD : REC    
                    end
            
            :REC  => x.swap = SUSC
            _     => error("Hia => Health status not known to @match")
        end
    end
end


function dailycontact(x::Human, P::HiaParameters, ag1, ag2, ag3, ag4, newborns, first, second, third)
    ## the daily contact with a human.. tranmission can occure
    rn = rand()
    ag = jackson_agegroup(x.age) ## determine the Jackson agegroup 
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
        x_rnd = rand(newborns)
    elseif agtocontact == 2
        x_rnd = rand(first)            
    elseif agtocontact == 3
        x_rnd = rand(second)            
    elseif agtocontact == 4
        x_rnd = rand(third)            
    else
        error("cant happen")
    end        
    ## at this point, human x and randhuman are going to contact each other.         
    ## check if transmission criteria is satisfied
    t = (x.health == SUSC || x.health == REC) && (x_rnd.health == CAR || x_rnd.health == SYMP)
    y = (x_rnd.health == SUSC || x_rnd.health == REC) && (x.health == CAR || x.health == SYMP)  
    if t
        transmission(x, x_rnd, P)
    elseif y 
        transmission(x_rnd, x, P)
    end          
    x.meetcnt += 1
    x_rnd.meetcnt += 1       
end


function transmission(susc::Human, sick::Human, P::HiaParameters)
    ## computes the transmission probability using the baseline for a susc and a sick person. If person is carriage, there is an automatic 50% reduction in beta value.
    ## can only make the person swap to latent!
    ## error check
    if (sick.health != CAR) && (sick.health != SYMP) 
        error("Hia Model => transmission() -- sick person is not actually sick")
    end

    ## use the beta_agegroup information to extract the right beta value from parameters   
    beta = 0.0
    ag = sick.agegroup_beta
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
    trans = (sick.health == CAR) ? beta*P.carriagereduction*(1 - susc.plvl) : beta*(1 - susc.plvl)
    if rand() < trans        
        susc.swap = LAT
    end
end

function swap(h::Human, P::HiaParameters)
    ## this function moves the human to a new compartment. 
    ## NOTE: IT dosnt SET the SWAP BACK TO NODEF.. do it manually 
    ##  OR CALL THE update() function.
    ## if moving to LATENT, calculate their path, and reset their invasive. 
    ## do not reset their invasive if NOT moving to latent.. this is because 
    ## invasive is set when moving to SYMP, so either set invasive = false when 
    ## they recover, OR (current solution) invasive = false when going to latent
    ## this function also updates their personal counters.

    ## ** see comment below on setting the variables (especially path) in correct order
    ## context specific checks 
    if h.swap == UNDEF  
        ## only run the function if swap is set. 
        return nothing
    end

    ## swapping to inv
    if h.swap == INV                      
        ## they are swapping to INV.. check if they will die using case fatality ratio
        h.invdeath = rand() < P.casefatalityratio ? true : false
        if h.invdeath == false 
            ## not dying, check what kind of invasive they will be. 
            bin = rand(Categorical([P.invmeningitis, P.invpneumonia, P.invother]))
            ## bin = 1, 2, 3 
            h.invtype = INVTYPE(bin)
        end 
    end  ## no need for an else... person can never become invasive again (or shouldnt)

    # common variables for all compartments    
    oldhealth = h.health ## need to pass into pathtaken()
    h.health = h.swap
    h.timeinstate = 0    ## they are swapping to new state, reset their time.
    h.statetime = statetime(h, P)  ## REMEMBER TO SWAP FIRST .. this gets the statetime of their current health
    h.path = h.health == LAT ? pathtaken(oldhealth, h) : 0
    ## get their path, path depends on protection lvl  - so always update path BEFORE protection lvl. 
    ## ie, if the person is swappning to latent (ie, x.health = latent set above), protection() in the next line will return 0 for path taken.
    ## slight inconvenient "feature": when transferring from REC -> SUS (ie, health = SUS, oldhealth = REC), the pathtaken is "4".. however, the person's path isnt actually determined until he moves to latent
    h.plvl = protection(h) ## this will get a new protection level, based on the new health we just set above

    ## update individual counters.
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
    if x.swap != UNDEF
        ## run swap function
        swap(x, P)

        ## run data collection
        collect(x, DC, time)

        ## if the swap is dead.. replace them. 
        if x.swap == DEAD
            newborn(x)  ## make the person a newborn        
        else ## reset their swap.             
            x.swap = UNDEF
        end
    end
end

