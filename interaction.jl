
function dailycontact_old(h::Array{Human}, P::HiaParameters)
    ## goes through every human, and assigns a contact. Check for transmission. 

    # ## filter humans by agegroup
    newborns = find(x -> x.age < 365, h)
    first = find(x -> x.age >= 365 && x.age < 1460, h)
    second = find(x -> x.age >= 1460 && x.age < 3285, h)    
    third = find(x -> x.age >= 3285, h)
    cmt = distribution_contact_transitions()  ## get the contact transmission matrix. 
    
    #cmt

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

function dailycontact_oldtwo(h::Array{Human}, P::HiaParameters, ag1, ag2, ag3, ag4)
 ## goes through every human, and assigns a contact. Check for transmission. 

    # ## filter humans by agegroup
    newborns = find(x -> x.age < 365, h)
    first = find(x -> x.age >= 365 && x.age < 1460, h)
    second = find(x -> x.age >= 1460 && x.age < 3285, h)    
    third = find(x -> x.age >= 3285, h)
   
    for i in 1:P.gridsize  ## take advantage of linear indexing
        #for each person, get a random number
        rn = rand()
        ag = agegroup(h[i].age)       
        if ag == 1 
            dist = ag1
        elseif ag == 2 
            dist = ag2
        elseif ag == 3
            dist = ag3
        else 
            dist = ag4
        end  
        agtocontact = rand(dist)#ff(ag, cmt)#findfirst(y -> rn <= y, dist)
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
        t = (h[i].health == SUSC || h[i].health == REC) && (h[randhuman].health == CAR || h[randhuman].health == SYMP || h[randhuman].health == PRE)
        y = (h[randhuman].health == SUSC || h[randhuman].health == REC) && (h[i].health == CAR || h[i].health == SYMP || h[i].health == PRE)  
        if t
            transmission(h[i], h[randhuman], P)
        elseif y 
            transmission(h[randhuman], h[i], P)
        end        
        h[i].dailycontact = randhuman
        h[i].meetcnt += 1
        h[randhuman].meetcnt += 1        
    end 

end
