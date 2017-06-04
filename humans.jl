## sets up the humans

type Human 
    health::HEALTH
    swap::HEALTH
    age::Int64      ## age in days  - 360 
    agegroup::Int64 #deprecated - dont need
    gender::GENDER
    statetime::Int64
    timeinstate::Int64
    cohortid::Int64 #deprecated - dont need
    protectlvl::Float64
    protecttime::Int64
    meetcount::Int64         ## total meet count. how many times this person has met someone else.    
    dailycontact::Int64      ## not needed ?? ## who this person meets on a daily basis. 
    
    ## constructor:: empty human - set defaults here
    ##  if changing, makesure to add/remove from new() function
    Human( health = SUSC, swap = UNDEF,
           age = 0, agegroup = 0, gender = MALE,
           statetime = typemax(Int64), timeinstate = -1,
           cohortid = 0, protectlvl = 0, protecttime = 0, meetcount = 0, dailycontact = 0) = new(health, swap, 
                               age, agegroup, gender, 
                               statetime, timeinstate,
                               cohortid, protectlvl, protecttime, meetcount, dailycontact)
end


function initialize(h::Array{Human},P::HiaParameters)
    for i = 1:P.gridsize
        h[i] = Human()
    end
end

function demographics(h::Array{Human}, P::HiaParameters)
    ## get the distribution
    age_cdf = distribution_age()
    for i = 1:P.gridsize
        rn = rand()
        ## the distribution is index 1-based so if we get index one below, this means they are under 1 years old
        ageyear = findfirst(x -> rn <= x, age_cdf)
        ageyear = ageyear - 1 ## since distribution is 1-based
        h[i].age =  rand(ageyear*365:ageyear*365 + 365)   ## convert to days
        h[i].gender = rand() < 0.5 ? FEMALE : MALE
    end
    return     
end


function ageincrease(h::Array{Human}, P::HiaParameters, deathprobs)
    ## this function increases age, and also checks for death. It also increase their timeinstate by one.
    ## this function can be optimized. 

      ## dprobs[1][...] male array, dprobs[2][...] female array
    for i = 1:P.gridsize
        h[i].age += 1  
        ## check for deaths using this new age
        if h[i].age < 360  ## CHECK AT A MONTHLY BASIS? YESS!! fix this
            ## baby is newborn, check for infant mortality
            if rand() < dprobs[Int(h[i].gender)][1] ## first element of death distribution corresponds to the death from 0 - 12 months
                setswap(h[i], DEAD) ## swap to dead
            end
        else 
            ## age is bigger than 1 year, check for yearly death
            if mod(h[i].age, 365) == 0
                ageyears = Int(h[i].age/365)
                if rand() < dprobs[Int(h[i].gender)][ageyears]
                    setswap(h[i], DEAD)
                end
            end
        end                 
    end
end

setswap(h::Human, swapto::HEALTH) =  h.swap = h.swap == UNDEF ? swapto : h.swap ## this function correctly sets the swap for a human.


function update(P::HiaParameters)
    ## this function updates the lattice
    swaps = find(x -> x.swap != UNDEF, humans)
    
    h.health = state
    h.statetime = statetime(state, P)
    h.timeinstate = 0
    h.swap = UNDEF
end


function dailycontact(h::Array{Human}, P::HiaParameters)
    ## goes through every human, and assigns a contact. Check for transmission. 

    ## filter humans by agegroup
    newborns = find(x -> x.age < 365, h)
    first = find(x -> x.age >= 365 && x.age < 1460, h)
    second = find(x -> x.age >= 1460 && x.age < 3285, h)    
    third = find(x -> x.age >= 3285, h)

    cmt = distribution_contact_transitions()  ## get the contact transmission matrix. 
    for i = 1:P.gridsize
        #for each person, get a random number
        rn = rand()
        ag = agegroup(h[i].age)  #function returns 1 - 4 corresponding to row of contact matrix
        dist = cmt[ag, :]
        #println("human $i is age: $(h[i].age) with group: $(agegroup(h[i].age)) - distribution assigned was $dist")
        agtocontact = findfirst(x -> rn <= x, dist)
        if agtocontact == 1
            #println("a")
            randhuman = rand(newborns)
        elseif agtocontact == 2
            #println("b")            
            randhuman = rand(first)            
        elseif agtocontact == 3
            #println("c")            
            randhuman = rand(second)            
        elseif agtocontact == 4
            #println("d")            
            randhuman = rand(third)            
        else
            error("cant happen")
        end        
        ## at this point, human i and randhuman are going to contact each other.         
        ## check if transmission criteria is satisfied
        t = (h[i].health == SUSC || h[i].health == REC) && (h[randhuman].health == CAR || h[randhuman].health == SYMP)
        y = (h[randhuman].health == SUSC || h[randhuman].health == REC) && (h[i].health == CAR || h[i].health == SYMP)  
        if t
            transmission(h[i], h[randhuman], P)
        elseif y 
            transmission(h[randhuman], h[i], P)
        end
        
        h[i].dailycontact = randhuman
        h[i].meetcount += 1
        h[randhuman].meetcount += 1        
    end 
end

function transmission(susc::Human, sick::Human, P::HiaParameters)
    ## computes the transmission probability using the baseline for a susc and a sick person. If person is carriage, there is an automatic 50% reduction in beta value.
    warn("Hia Model => Not tested -- check if incoming sick human is sick")
    trans = sick.health == CAR ? P.beta*0.5*(1 - susc.protectlvl) : P.beta*(1 - susc.protectlvl)
    if rand() < trans
        setswap(susc, LAT)
    end
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
    