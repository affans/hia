
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
end