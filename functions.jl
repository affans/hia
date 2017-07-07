
function todo()
    warn("Hia model => √ calculate probability distribution for death, and implement code")
    warn("Hia model => √ update pathtaken() when vaccine is implemented")    
    warn("Hia model => √ remove find functions, and optimize - demographics")
    warn("Hia model => √ check if dosesgiven > 0 => pvaccine == true.")
    warn("Hia model => √ check if bvaccine = true => dosesgiven = 3.")
    warn("Hia model => √ ageplusplus can be absorbed into the daily lattice update function")
    warn("Hia model => √ presymptomatic is also infectious - reduction 50% - done preliminary")
    warn("Hia model => √ if invasive before, always mark as false")   
    warn("Hia model => √ Implement death in invasive compartment")
    warn("Hia model => √ Use four beta values instead of one")
    warn("Hia model => think of a way to implement plotting for changing age distribution")
    warn("Hia model => √ algorithm to track a human")
    warn("Hia model => profile main() and check bottlenecks")
    warn("Hia model => verify age brackets for contact matrix")
    warn("Hia model => clean up cmt-ag variables in main()")  
    warn("Hia model => clean up bins variables in main()")  
    warn("Hia model => √ disease specific hospitalization length of stay")  
    warn("Hia model => in groupcounts - processed multiple times in processresults()")  
    warn("Hia model => if infected, see if sickfrom ID is valid. ")  
    
    
    
    
    
end

function track(h::Human)
    println("...health")
    println("       cur/swap: $(h.health)/$(h.swap)")
    println("       path:     $(h.path)")
     println("      plvl:     $(h.plvl)")
    println("...demographics")
    println("       age/sex:  $(h.age) / $(h.gender)")
    println("       age(yrs): $(h.age/365)")    
    println("...model (_instate) variables")
    println("       time:     $(h.timeinstate)")
    println("       expiry:   $(h.statetime)")
    #println("...vaccine")
    #println("       booster:  $(h.bvaccine)")
    #println("       # doses:  $(h.dosesgiven)")
    
end

function carriageprobs(pa::Integer, P::HiaParameters)
    ## get the parameters for the path integer - parameter: pa
    minprob = 0.0
    maxprob = 0.0
    symprob = 0.0
    @match pa begin
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
        _ => error("Hia Model => carriage/symptomatic out of bounds")
    end
    return minprob, maxprob, symprob
end

function pathtaken(oldhealth::HEALTH, h::Human)
    ## calculates which path they will take based on a decision tree
    ## the human is already latent at this point... thats why we pass in 
    ## `oldhealth` to see what path they will take. 
    st = 0  
    #rintln("pathtaken(): oldhealth = $oldhealth")  
    if oldhealth == REC 
        # person got sick while in recovery period, fixed path 4
        st = 4
    elseif oldhealth == SUSC
        # person got sick while as a susceptible
        if h.age < 1825 
            # <5 years
            if h.plvl == 0.0
                st = 1
            elseif h.plvl == 0.50
                st = 2
            elseif h.plvl > 0.50 ### implies primary doses have been given
                if h.bvaccine 
                    st = 4
                else 
                    st = 3
                end
            else 
                track(h, 1)
                error("Hia model => pathtaken() combination not found")
            end
        else
            # age >= 5, and a susceptible - (either susceptible by birth or susceptible by recovery)
            if h.age > 3650 && h.age < 21900
                st = 3 
            else 
                st = 2
            end
        end
    else 
        st = 0
    end   
    return st
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
            else ## they are over 5 years old, automatic 0.5 -- if they have booster, it will expire. 
                retval = 0.5
            end
        end    
    else 
        ## they are in a compartment other than susc/rec.. no need for protection level
        retval = 0.0
    end
    return retval
end



function statetime(x::Human, P::HiaParameters)::Int32
    ## this returns the statetime for everystate..
    ## it uses their CURRENT HEALTH.. so if using for swap purposes, SWAP FIRST then get statetime. 
   
    st = 0 ## return variable
    @match Symbol(x.health) begin
        :SUSC  => st = typemax(Int32)  ## no expiry for suscepitble
        :LAT   => 
                begin
                    #d = LogNormal(P.latentshape, P.latentscale)
                    #st = max(P.latentmin, min(Int(ceil(rand(d))), P.latentmax))
                    st = Int(round(rand(Truncated(LogNormal(P.latentshape, P.latentscale), P.latentmin, P.latentmax))))
                end
        :CAR   => st = rand(P.carriagemin:P.carriagemax) ## fixed 50 days for carriage?
        :SYMP  => st = rand(Truncated(Poisson(P.symptomaticmean), P.symptomaticmin, P.symptomaticmax))
        :INV   =>
                begin
                    if x.invdeath
                        st = rand(Truncated(Poisson(P.hospitalmean_death), P.hospitalmin_death, P.hospitalmax_death))
                    else 
                        st = hospitalinfo(x, P)[1] ## first element returns length of stay
                    end
                end       
        :REC   => st = rand(P.recoveredmin:P.recoveredmax)
        :DEAD  => st = typemax(Int32)        
        _   => throw("Hia model => statetime passed in non-health enum")
    end
    return st
end


function hospitalinfo(x::Human, P::HiaParameters)
    ## this function is called by statetime() when the person is invasive
    ##  when the person is invasive, with no death - we want length of stay 
    ##  based on type of invasive disease and age.  see parameter file for source.
    ## this function also returns the cost of staying in the hospital PER DAY
    l = 0
    c = 0
    if x.health != INV
        return l, c
    end
    if x.age <= 365     ## 1 year
        if x.invtype == PNEU
            l = rand(3:7)
            c = 8739
        elseif x.invtype == NPNM
            l = rand(7:11)
            c = 10237
        else ## its one of meningitis
            l = rand(10:14)
            c = 11076
        end                             
    elseif x.age > 365 && x.age <= 2555 # 1-7 years
        if x.invtype == PNEU
            l = rand(2:6)
            c = 7554
        elseif x.invtype == NPNM
            l = rand(3:7)
            c = 7088
        else 
            l = rand(7:11)
            c = 8856
        end                
    elseif x.age > 2555 && x.age <= 6205 #8 - 17
        if x.invtype == PNEU
            l = rand(3:7)
            c = 9649
        elseif x.invtype == NPNM
            l = rand(5:9)
            c = 7508
        else 
            l = rand(3:7)
            c = 6833
        end                
    elseif x.age > 6205 && x.age <= 21535 # 18 - 59
        if x.invtype == PNEU
            l = rand(6:10)
            c = 13278
        elseif x.invtype == NPNM
            l = rand(7:11)
            c = 11696
        else 
            l = rand(5:9)
            c = 9994
        end                
    elseif x.age > 21535 && x.age <= 29200 ## 60 - 80
        if x.invtype == PNEU
            l = rand(6:10)
            c = 13093
        elseif x.invtype == NPNM
            l = rand(9:13)
            c = 13645
        else 
            l = rand(9:13)
            c = 16088
        end
    else x.age > 29200 ## 80+
        if x.invtype == PNEU
            l = rand(6:10)
            c = 9983
        elseif x.invtype == NPNM
            l = rand(10:14)
            c = 12866
        else 
            l = rand(17:21)
            c = 24479
        end                
    end
    return l, c
end


function jackson_agegroup(age::Integer)
    ## Jackson Agegroups!
    ## these agegroups only applicable for contacts - used in function dailycontacts()
    @match age begin
        0:365       => 1  # 0 - 1  ## completed first year
        366:1460    => 2  # 2 - 4  ## completed upto 4 years
        1461:3285   => 3  # 5- 10  ## starting 5th year, completed 10 years
        3285:36501  => 4  # 10+
        _           => error("Hia Model => age too large in jackson_agegroup()")
    end
end

function beta_agegroup(age::Integer)
    ## returns one of the beta values from the parameter list

    ## If: Changing the number (or even values of the age group), check datacollection vectors.
    ## for example in human.jl, update(), DC vectors are updated by latent[dayofsim, AGEGROUP] +=1 
    @match age begin
        0:364         => 1     # 0 - 1
        365:1824      => 2     # 2 - 5 
        1825:3649     => 3     # 5 - 10
        3650:21899    => 4     # 10 - 60
        21900:40000   => 5     # 60 +         
        _           => error("Hia Model => age too large in agegroup()")
    end
end

function insertrandom(h::Array{Human{Int64}}, P::HiaParameters, s::HEALTH)
    i = rand(1:P.gridsize) ## select a random human
    # set the swap and run the update function manually
    h[i].swap = s
    swap(h[i], P)
    h[i].swap = UNDEF
    return i
end
