function statetime(x::Human, P::HiaParameters)
    ## this returns the statetime for everystate..
    ## it uses their CURRENT HEALTH.. 
    ## so if using for swap purposes, SWAP FIRST then get statetime. 
   
    r = 0 ## return variable
    @match Symbol(x.health) begin
        :SUSC  => r = typemax(Int64)  ## no expiry for suscepitble
        :LAT   => 
                begin
                   r = Int(round(rand(Truncated(LogNormal(P.latentshape, P.latentscale), P.latentmin, P.latentmax))))
                end
        :CAR   => r = rand(P.carriagemin:P.carriagemax) ## fixed 50 days for carriage?
        :SYMP  => r = rand(Truncated(Poisson(P.symptomaticmean), P.symptomaticmin, P.symptomaticmax))
        :INV   => r = lengthofstay(x, P)       
        :REC   => r = rand(P.recoveredmin:P.recoveredmax)
        :DEAD  => r = typemax(Int64)        
        _   => throw("Hia model => statetime passed in non-health enum")
    end
    return r
end

function pathprobability(t::Integer, P::HiaParameters)
    ## gets the probabilities of going to carriage/symptomatic/invasive for a PATH integer. PATH could be 1, 2, 3, 4 -- assigned when person is becoming latent. 
    minprob = 0.0
    maxprob = 0.0
    symprob = 0.0
    @match t begin
        1 =>begin 
                minprob = P.pathone_carriage_min
                maxprob = P.pathone_carriage_max
                symprob = P.pathone_symptomatic
            end
        2 =>begin 
                minprob = P.pathtwo_carriage_min
                maxprob = P.pathtwo_carriage_max
                symprob = P.pathtwo_symptomatic
            end
        3 =>begin 
                minprob = P.paththree_carriage_min
                maxprob = P.paththree_carriage_max
                symprob = P.paththree_symptomatic                
            end
        4 =>begin 
                minprob = P.pathfour_carriage_min
                maxprob = P.pathfour_carriage_max
                symprob = P.pathfour_symptomatic                
            end
        5 =>begin 
                minprob = P.pathfive_carriage_min
                maxprob = P.pathfive_carriage_max
                symprob = P.pathfive_symptomatic                
            end
        6 =>begin 
                minprob = P.pathsix_carriage_min
                maxprob = P.pathsix_carriage_max
                symprob = P.pathsix_symptomatic                
            end
        7 =>begin 
                minprob = P.pathseven_carriage_min
                maxprob = P.pathseven_carriage_max
                symprob = P.pathseven_symptomatic                
            end
        _ => error("Hia Model => invalid path number given")
    end
    return minprob, maxprob, symprob
end

function pathtaken(oldhealth::HEALTH, h::Human)
    ## calculates which path they will take based on a decision tree. This function is run when the person is becoming latent, and depends on HOW they got to latent.
    ## the human is already latent at this point... thats why we pass in `oldhealth` to see what path they will take. 
    ## path definitions and probabilities are in the excel file.
    if oldhealth == REC 
        return 6
    elseif oldhealth == SUSC # person got sick while as a susceptible
        if h.latcnt > 0 
            return 7
        end
        if !h.pvaccine   ## no vaccine, natural immunity at age 5.
            if h.age <= 1825 
                return 1
            else 
                return 7
            end
        end
        if h.dosesgiven == 1 && h.age < h.vaccineexpirytime
            return 2
        elseif h.dosesgiven == 2 && h.age < h.vaccineexpirytime
            return 3
        elseif h.dosesgiven == 3 && h.age < h.vaccineexpirytime && h.bvaccine == false
            return 4
        elseif h.dosesgiven == 4 && h.age < h.vaccineexpirytime && h.bvaccine == true
            return 5
        else # vaccine induced time has expired. 
            return 7 
        end
    end
end

function protection(h::Human)
    ## this assigns the proper protection level - based on health, recovery, age, and vaccine combinations
    ## see notes for details, and parameter file for references.
    ## note- this assigns their protection level according to their CURRENT health and not their swap. 
    
    r = 0.0  # return value
    if h.health == REC 
        r = 0.95
    elseif h.health == SUSC 
        if h.latcnt > 0  ## they have been atleast sick once, so automatic 50% protection            
            r = 0.5
        else
            if !h.pvaccine   ## no vaccine, natural immunity at age 5.
                r = h.age < 1825 ? 0.0 : 0.5
            else
                ## individual h has primary (and possibly booster vaccine)
                if h.dosesgiven == 1 && h.age < h.vaccineexpirytime
                    r = 0.5
                elseif h.dosesgiven == 2 && h.age < h.vaccineexpirytime
                    r = 0.80
                elseif h.dosesgiven == 3 && h.age < h.vaccineexpirytime && h.bvaccine == false
                    r = 0.85
                elseif h.dosesgiven == 4 && h.age < h.vaccineexpirytime && h.bvaccine == true
                    r = rand()*(0.95 - 0.85)+0.85
                else # vaccine induced time has expired. 
                    r = 0.5 
                end
            end
        end    
    else 
        ## they are in a compartment other than susc/rec.. no need for protection level
        r = 0.0
    end
    return r
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
    if rand() < trans   ## succesfull transfer of pathogen.      
        susc.swap = LAT
        susc.sickfrom = sick.agegroup_beta ## we only care about which agegroup made this person sick
    end
end

function lengthofstay(x::Human, P::HiaParameters)
    ## this function returns the length of stay in hospital, called by statetime() when the person is invasive
    
    l = 0 ## return value 
    if x.invdeath
        l = rand(Truncated(Poisson(P.hospitalmean_death), P.hospitalmin_death, P.hospitalmax_death))
        return l
    end  
    
    
    if x.age <= 365     ## 1 year
        if x.invtype == PNEU
            l = rand(3:7)
        elseif x.invtype == NPNM
            l = rand(7:11)
        else ## its one of meningitis
            l = rand(10:14)
        end                             
    elseif x.age > 365 && x.age <= 2555 # 1-7 years
        if x.invtype == PNEU
            l = rand(2:6)
        elseif x.invtype == NPNM
            l = rand(3:7)
        else 
            l = rand(7:11)
        end                
    elseif x.age > 2555 && x.age <= 6205 #8 - 17
        if x.invtype == PNEU
            l = rand(3:7)
        elseif x.invtype == NPNM
            l = rand(5:9)
        else 
            l = rand(3:7)
        end                
    elseif x.age > 6205 && x.age <= 21535 # 18 - 59
        if x.invtype == PNEU
            l = rand(6:10)
        elseif x.invtype == NPNM
            l = rand(7:11)
        else 
            l = rand(5:9)
        end                
    elseif x.age > 21535 && x.age <= 29200 ## 60 - 80
        if x.invtype == PNEU
            l = rand(6:10)
        elseif x.invtype == NPNM
            l = rand(9:13)
        else 
            l = rand(9:13)
        end
    else x.age > 29200 ## 80+
        if x.invtype == PNEU
            l = rand(6:10)
        elseif x.invtype == NPNM
            l = rand(10:14)
        else 
            l = rand(17:21)
        end                
    end
    return l
end

function hospitalcost(x::Human, P::HiaParameters)    
    ## this function returns the hospital costs PER DAY for a particular person x.
    c = 0  ## return value    
    if x.health == INV && x.invdeath  
        c = P.cost_averagehospital  ## use the average cost
        return c
    end
    if x.age <= 365     ## 1 year
        if x.invtype == PNEU
            c = 8739
        elseif x.invtype == NPNM
            c = 10237
        else ## its one of meningitis
            c = 11076
        end                             
    elseif x.age > 365 && x.age <= 2555 # 1-7 years
        if x.invtype == PNEU
            c = 7554
        elseif x.invtype == NPNM
            c = 7088
        else 
            c = 8856
        end                
    elseif x.age > 2555 && x.age <= 6205 #8 - 17
        if x.invtype == PNEU
            c = 9649
        elseif x.invtype == NPNM
            c = 7508
        else 
            c = 6833
        end                
    elseif x.age > 6205 && x.age <= 21535 # 18 - 59
        if x.invtype == PNEU
            c = 13278
        elseif x.invtype == NPNM
            c = 11696
        else 
            c = 9994
        end                
    elseif x.age > 21535 && x.age <= 29200 ## 60 - 80
        if x.invtype == PNEU
            c = 13093
        elseif x.invtype == NPNM
            c = 13645
        else 
            c = 16088
        end
    else x.age > 29200 ## 80+
        if x.invtype == PNEU
            c = 9983
        elseif x.invtype == NPNM
            c = 12866
        else 
            c = 24479
        end                
    end
    return c
end


function jackson_agegroup(age::Integer)
    ## Jackson Agegroups!
    ## these agegroups only applicable for contacts - used in function dailycontacts()
    @match age begin
        0:365       => 1  # 0 - 1  ## completed first year
        366:1460    => 2  # 2 - 4  ## completed upto 4 years
        1461:3285   => 3  # 5- 10  ## starting 5th year, completed 10 years
        3285:43800  => 4  # 10+
        _           => error("Hia Model => age too large in jackson_agegroup()")
    end
end

function beta_agegroup(age::Integer)
    ## returns one of the beta values from the parameter list
    @match age begin
        0:364         => 1     # 0 - 1
        365:1824      => 2     # 2 - 5 
        1825:3649     => 3     # 5 - 10
        3650:21899    => 4     # 10 - 60
        21900:40000   => 5     # 60 +         
        _           => error("Hia Model => age too large in agegroup()")
    end
end

function lifetime_reduction(invtype::Integer, P::HiaParameters)
    ## determine if this person will have their life reduced
    st = 0
    if P.lfreductiononoff == 0 
        return st
    else
        @match invtype begin
            1:7         => st = rand(P.lfreducemajormin:P.lfreducemajormax)
            #8:14        => st = 0# rand(P.lfreduceminormin:P.lfreduceminormax) 
            _           => st = 0
        end
        st
    end   
end

function insertrandom(h::Array{Human{Int64}}, P::HiaParameters)
    i = rand(1:P.gridsize) ## select a random human
    # set the swap and run the update function manually
    h[i].swap = LAT
    swap(h[i], P)  
    return i
end
