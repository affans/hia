# sets up the humans

type Human 
    health::HEALTH
    swap::HEALTH
    path::Int8
    inv::Bool
    age::Int32      ## age in days  - 360 
    gender::GENDER
    statetime::Int32
    timeinstate::Int32
    protectlvl::Float16
    protecttime::Int32
    meetcount::Int32         ## total meet count. how many times this person has met someone else.    
    dailycontact::Int32      ## not needed ?? ## who this person meets on a daily basis. 
    
    ## constructor:: empty human - set defaults here
    ##  if changing, makesure to add/remove from new() function
    Human( health = SUSC, swap = UNDEF, path = 0, inv = false,
           age = 0, gender = MALE,
           statetime = typemax(Int32), timeinstate = -1,
           protectlvl = 0, protecttime = 0, meetcount = 0, dailycontact = 0) = new(health, swap, path, inv, 
                               age, gender, 
                               statetime, timeinstate,
                               protectlvl, protecttime, meetcount, dailycontact)
end


function initialize(h::Array{Human},P::HiaParameters)
    for i = 1:P.gridsize
        h[i] = Human()
    end
end

function demographics(h::Array{Human}, P::HiaParameters)
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


function ageplusplus(h::Array{Human}, P::HiaParameters)
    ## dprobs[1][...] male array, dprobs[2][...] female array
    for x in h
        ## increase age by one day 
        x.age += 1  
        ## assign 50% protection level to all those above 5 years old and are susceptible
        if x.age >= 1825 && x.health == SUSC 
            x.protectlvl = 0.50
        end
        ## to do: implement naturaldeath()
    end
end

function timeplusplus(h::Array{Human}, P::HiaParameters)
    @simd for x in h ## for each human
        x.timeinstate += 1
        if x.timeinstate > x.statetime 
            ## move their compartments
            @match Symbol(x.health) begin
                :SUSC => error("Hia Model => susc cannot expire")
                :LAT  => begin ## latency has expired, moving to either carriage or presymptomatic, depends on age
                            ## get their min/max carriage probs and whether they will go to invasive
                            minp, maxp, invp  = carriageprobs(x.path, P)  ## path should've been set when they became invasive
                            pc = rand()*(maxp - minp) + minp  ## randomly sample probability to carriage from range
                            x.swap = rand() < pc ? CAR : SYMP                            
                            # if the person is going to symptomatic, check if they will go to invasive
                            if x.swap == SYMP
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




function update(h::Array{Human}, P::HiaParameters)
    ## this function updates the lattice. 

    ## find all humans that have a swap set
    #swaps = find(x -> x.swap != UNDEF, humans)
    for i in 1:P.gridsize        
        if h[i].swap != UNDEF
            if h[i].swap == SUSC
                h[i].path = 0
            end
            if h[i].swap == LAT 
                h[i].path = pathtaken(h[i], P) ## need to figure out which path they will take once they go out of latent. need to do this now, because the path depends on whether they were susceptible/recovered                                        
                h[i].inv = false ## reset their invasive... (in case the person has recovered from an invasive disease from before, thus this variable would've been set to true.)                 
                ## wwhen the person switches out of latent, this will be assigned again (see timeplusplus())
            end    
            ## common properties of switching compartments
            h[i].health = h[i].swap
            h[i].statetime = statetime(h[i].swap, P)
            h[i].timeinstate = 0
            h[i].swap = UNDEF
        end
    end
end


function dailycontact(h::Array{Human}, P::HiaParameters)
    ## goes through every human, and assigns a contact. Check for transmission. 

    # ## filter humans by agegroup
    newborns = find(x -> x.age < 365, h)
    first = find(x -> x.age >= 365 && x.age < 1460, h)
    second = find(x -> x.age >= 1460 && x.age < 3285, h)    
    third = find(x -> x.age >= 3285, h)
    cmt = distribution_contact_transitions()  ## get the contact transmission matrix. 
    
    for x in h  ## take advantage of linear indexing
        #for each person, get a random number
        rn = rand()
        ag = agegroup(x.age)  #function returns 1 - 4 corresponding to row of contact matrix
        dist = cmt[ag, :]        
        agtocontact = findfirst(y -> rn <= y, dist)
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
        ## at this point, human i and randhuman are going to contact each other.         
        ## check if transmission criteria is satisfied
        t = (x.health == SUSC || x.health == REC) && (h[randhuman].health == CAR || h[randhuman].health == SYMP)
        y = (h[randhuman].health == SUSC || h[randhuman].health == REC) && (x.health == CAR || x.health == SYMP)  
        if t
            transmission(h[i], h[randhuman], P)
        elseif y 
            transmission(h[randhuman], h[i], P)
        end
        
        x.dailycontact = randhuman
        x.meetcount += 1
        h[randhuman].meetcount += 1        
    end 
end

function transmission(susc::Human, sick::Human, P::HiaParameters)
    ## computes the transmission probability using the baseline for a susc and a sick person. If person is carriage, there is an automatic 50% reduction in beta value.
    ## can only make the person swap to latent!
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
    