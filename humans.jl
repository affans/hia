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
    gender::GENDER     ## gender - 50% male/female
    meetcnt::Int32     ## total meet count. how many times this person has met someone else.    
    dailycontact::Int32## not needed ?? ## who this person meets on a daily basis. 
    ## vaccine
    pvaccine::Bool     ## if primary vaccine is turned on
    bvaccine::Bool     ## if booster vaccine is turned on
    dosesgiven::Int8   ## doses given, 1 2 3 after primary
    
    # constructor:: empty human - set defaults here
    ##  if changing, makesure to add/remove from new() function
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
           age = 0, gender = MALE,
           meetcnt = 0, dailycontact = 0,
           pvaccine = false, bvaccine = false, 
           dosesgiven = 0) = new(health, swap, path, inv, plvl, ptime, latcnt, symcnt, invcnt, timeinstate, statetime, age, gender, meetcnt, dailycontact, pvaccine, bvaccine, dosesgiven) 
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
        x.gender = rand() < 0.5 ? FEMALE : MALE
        x.plvl = protection(x)
    end
    return nothing
end

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
                                    x.inv = rand() < invp ? true : false
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

setswap(h::Human, swapto::HEALTH) =  h.swap = h.swap == UNDEF ? swapto : h.swap ## this function correctly sets the swap for a human.

function swap(h::Human, P::HiaParameters)
    # this function moves the human to a new compartment. This is the final update version 

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
    h.plvl = protection(h)

    ## update individual counters, and pathtaken/protection cases.
    if h.health == LAT   
        h.latcnt += 1
    elseif h.health == SYMP
        h.symcnt += 1
    elseif h.health == INV
        h.invcnt += 1    
    end
end

function protection(h::Human)
    ## this assigns the proper protection level - based on health, recovery, age, and vaccine combinations
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


function update(h::Array{Human}, P::HiaParameters, DC::DataCollection, time::Int64)
    ## this function updates the lattice, counts incidence data, increases age, and calculates death
    ## get the death distribution.
    #pdm, pdf = distribution_ageofdeath()  ## distribution of deaths, do we need this every function?
    #dprobs = [pdm, pdf]

    @unpack lat, car, sym, inv, rec = DC ## unpack datacollection vectors 
    for x in h 
        x.age += 1 
        if x.age == 1825 ## 5 year mark, if susceptible, booster protection will expire and person will go to 0.5 protection level
            x.plvl = protection(x)
        end
        if x.swap != UNDEF
            ## collect our data
            if x.swap == LAT 
                lat[time] += 1
            elseif x.swap == CAR
                car[time] += 1
            elseif x.swap == SYMP
                sym[time] += 1
            elseif x.swap == INV
                inv[time] += 1
            elseif x.swap == REC
                rec[time] += 1
            end    
            ## apply the swap function
            swap(x, P)
        end
    end
end

function transmission(susc::Human, sick::Human, P::HiaParameters)
    ## computes the transmission probability using the baseline for a susc and a sick person. If person is carriage, there is an automatic 50% reduction in beta value.
    ## can only make the person swap to latent!
    if (sick.health != CAR) && (sick.health != SYMP) && (sick.health != PRE)
        error("Hia Model => transmission() -- sick person is not actually sick")
    end
    ## if they are carriage or presymptomatic - apply a 50% reduction. 
    trans = (sick.health == CAR || sick.health == PRE) ? P.beta*0.5*(1 - susc.plvl) : P.beta*(1 - susc.plvl)
    if rand() < trans        
        setswap(susc, LAT)
    end
end


function insertrandom(h::Array{Human}, P::HiaParameters, s::HEALTH)
    i = rand(1:P.gridsize) ## select a random human
    # set the swap and run the update functiona manually
    setswap(h[i], s)    
    swap(h[i], P)
    println("random human inserted at location $i")
    track(h[i], i)
    return i
end


function test()
    a = zeros(Int64, P.gridsize)
    @time dailycontact(humans, P, a)
    find(x -> x == 1, a)

    xx = find(x -> x.age >= 1460 && x.age < 3285, humans)
    con = zeros(Int64, length(xx))
    for i = 1:length(xx)
        con[i] = a[xx[i]]
    end
    find(x -> x==1, con)
    dailycontact(humans, P)
    find(x -> x.meetcount == 1, humans)

    checkdailycontact(h::Array{Human}) = length(find(x -> x.dailycontact > 0, h)) 


end
    