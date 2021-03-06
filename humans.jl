# sets up the humans
mutable struct Human{T <: Integer}
    ## disease parameters (modified in make() function)
    id::T                 ## ID of the human
    health::HEALTH     ## current health status
    swap::HEALTH          ## swap health status (works as "last status" also - see swap())
    path::T               ## the path they will take if they get sick
    invtype::INVSEQ       ## invasive sequlae
    invdeath::Bool        ## whether this human is invasive and will die
    plvl::Float64         ## protection level - 0 - 100%  
    latcnt::T             ## how many times this person has become latent
    carcnt::T             ## how many times this person has become carriage
    symcnt::T             ## how many times this person has become symptomatic
    invcnt::T             ## how many times this person has become invasive
    deadcnt::T            ## how many times this person has died. This variable shouldnt reset. 
    sickfrom::T           ## if person is infected, record the ID of the person who infects
    timeinstate::T        ## days spent in current health status   
    statetime::T          ## maximum amount of days spent in health status 
    age::T                ## age in days  - 365 days per year
    expectancy::T         ## life expectancy - however death is checked every year against a distribution
    expectancyreduced::T  ## if invasive, expectancy is reduced by this amount IN YEARS.. 0 means no reduction
    agegroup_beta::T      ## - NOT the jackson contact matrix group.
    gender::GENDER        ## gender - 50% male/female
    meetcnt::T            ## total meet count. how many times this person has met someone else.    
    pvaccine::Bool        ## if primary vaccine is turned on
    bvaccine::Bool        ## if booster vaccine is turned on
    dosesgiven::T         ## doses given, 1 2 3 after primary
    vaccineexpirytime::T        ## how long is this vaccine protection 
    
    # constructor:: empty human - set defaults here
    ##  if changing, makesure to add/remove from reset() function
    Human( id = 0,
           health = SUSC, 
           swap   = UNDEF, 
           path   = 0, 
           invtype = NOINV, 
           invdeath = false,
           plvl   = 0,
           latcnt = 0,
           carcnt = 0,
           symcnt = 0,
           invcnt = 0, deadcnt = 0, sickfrom = 0,
           timeinstate = 0, statetime = typemax(Int64), 
           age = 0, expectancy=0, expectancyreduced=0, 
           agegroup_beta = 0, 
           gender = MALE,
           meetcnt = 0, 
           pvaccine = false, bvaccine = false,
           dosesgiven = 0, 
           vaccineexpirytime = 0) = new(id, health, swap, path, invtype, invdeath, plvl, latcnt, carcnt, symcnt, invcnt, deadcnt, sickfrom, timeinstate, statetime, age, expectancy, expectancyreduced, agegroup_beta, gender, meetcnt, pvaccine, bvaccine, dosesgiven, vaccineexpirytime) 
end



function initialize(h::Array{Human{Int64}},P::HiaParameters)
    for i = 1:P.gridsize
        h[i] = Human{Int64}()
        h[i].id = i
    end
end

function demographics(h::Array{Human{Int64}}, P::HiaParameters)
    age_cdf = distribution_age()
    for x in h
        rn = rand()
        ## the distribution is index 1-based so if we get index one below, this means they are under 1 years old
        ageyear = findfirst(x -> rn <= x, age_cdf)
        ageyear = ageyear - 1 ## since distribution is 1-based
        x.age =  min(rand(ageyear*365:ageyear*365 + 365), 85*365)   ## convert to days // capped at 85 years old.. 
        x.agegroup_beta = beta_agegroup(x.age)
        ddist = distribution_expectancy(x.age)
        ## everyone has an expectancy
        x.expectancy = x.age + rand(ddist)*365 ## convert to days
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
    h.carcnt = 0
    h.symcnt = 0
    h.invcnt = 0
    h.sickfrom = 0
    h.timeinstate = 0
    h.statetime = typemax(Int64) 
    h.age = 0
    h.expectancy = rand(distribution_expectancy(0))*365 ## convert to days
    h.expectancyreduced = 0 
    h.agegroup_beta = beta_agegroup(0)
    h.gender = rand() < 0.5 ? FEMALE : MALE
    h.meetcnt = 0
    h.pvaccine = false 
    h.bvaccine = false 
    h.dosesgiven = 0
    h.vaccineexpirytime =0
end

function app(h::Human, P::HiaParameters)
    ## update age, agegroup, natural death, and protectionlvl at 5 years old
    ## output: age++, might possibly die
    h.age += 1   ## increase age by one
    tage = h.age ## store as temp

    # check at a yearly level for death, new protection level, and recalculate agegroup_beta
    if mod(tage, 365) == 0
        if tage == 1825  ## and year 5, check if protection needs to be changed.
            h.plvl = protection(h)
        end
        # every year, recalculate agegroup
        h.agegroup_beta = beta_agegroup(tage)

        # every year, check for death
        ageyears = Int(tage/365)
        eyears = Int(round(h.expectancy/365, 0)) ## expected years
        ryears = eyears - h.expectancyreduced
        if rand() < distribution_ageofdeath(ageyears, h.gender) || ageyears >= ryears
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
                        minp, maxp, symp  = pathprobability(x.path, P)  ## path should've been set when they became latent -- see swap() function. 
                        pc = rand()*(maxp - minp) + minp  ## randomly sample probability to carriage from range
                        if rand() < pc 
                            x.swap = CAR  ## going to carriage
                        else
                            ## going to symptomatic or invasive
                            if rand() < (1 - symp) && x.invcnt == 0
                                x.swap = INV
                            else 
                                x.swap = SYMP
                            end
                        end 
                    end
            :CAR  => x.swap = REC
            :SYMP => x.swap = REC
            :INV  => 
                    begin ## person is coming OUT of invasive
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
    
    ## pick a random number from the correct distribution    
    if ag == 1 
        agtocontact = rand(ag1)
    elseif ag == 2 
        agtocontact = rand(ag2)
    elseif ag == 3
        agtocontact = rand(ag3)
    else 
        agtocontact = rand(ag4)
    end  
    
    if agtocontact == 1
        if length(newborns) == 0 
            return nothing
        end
        x_rnd = rand(newborns)
    elseif agtocontact == 2
        if length(first) == 0 
            return nothing
        end
        x_rnd = rand(first)
    elseif agtocontact == 3
        if length(second) == 0 
            return nothing
        end
        x_rnd = rand(second) 
    elseif agtocontact == 4
        if length(third) == 0 
            return nothing
        end
        x_rnd = rand(third)
    else
        error("Hia Model => dailycontact() has agtocontact != 1, 2, 3, 4")
    end        

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
    return nothing      
end



function swap(h::Human, P::HiaParameters)    
    ## only run the function if swap is set. 
    if h.swap == UNDEF         
        return nothing
    end

    if h.swap == DEAD
        newborn(h)
        return nothing
    end

    ## swapping to inv
    if h.swap == INV                      
        ## they are swapping to INV.. check if they will die using case fatality ratio
        ## couple of things must happen: x.invdeath && x.invtype must be set accordingly.
        ## if invdeath == T, then invtype == NOINV (since this is the default value)
        ## if invdeath == F, then invtype == Integer
        
        h.invdeath = rand() < P.casefatalityratio ? true : false
        if h.invdeath == false 
            ## not dying, check what kind of invasive they will be. 
            id = rand(Categorical([P.prob_invas_men, P.prob_invas_pneu, P.prob_invas_npnm]))
            if id == 1 #they will have meningitis
                ## check whether it will be major or minor.
                td = distribution_sequlae(P)  ## categorical RV with 15 elements           
                h.invtype = INVSEQ(rand(td))  
                ## make sure the ENUM integer values and the CATEGORICAL order sequence matches.
                ## enum value 16/17 correspond to pneu/npnm but they will never be returned from a 15 element categorical array                
                h.expectancyreduced = lifetime_reduction(Int(h.invtype), P)
                
            elseif id == 2
                h.invtype = PNEU
            elseif id == 3                
                h.invtype = NPNM
            end
        end 
    end 

    if h.swap == REC
        h.sickfrom = 0  ## reset this variable. not terribly important, because if they get sick, it will rewrite. 
    end 

    # common variables for all compartments    
    oldhealth = h.health ## need to pass into pathtaken()
    h.health = h.swap
    h.timeinstate = 0    ## they are swapping to new state, reset their time.
    h.statetime = statetime(h, P)  ## REMEMBER TO SWAP FIRST .. this gets the statetime of their current health
    h.path = h.health == LAT ? pathtaken(oldhealth, h) : 0
    h.plvl = protection(h) 

    ## update individual counters based on the new health
    if h.health == LAT   
        h.latcnt += 1
    elseif h.health == CAR
        h.carcnt += 1
    elseif h.health == SYMP
        h.symcnt += 1
    elseif h.health == INV
        h.invcnt += 1    
    end      
    ## reset the swap back to undefined
    h.swap = UNDEF
    return nothing
end
