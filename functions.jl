
function todo()
    warn("Hia model => √ calculate probability distribution for death, and implement code")
    warn("Hia model => update pathtaken() when vaccine is implemented")    
    warn("Hia model => remove find functions, and optimize - demographics")
    warn("Hia model => check if dosesgiven > 0 => pvaccine == true.")
    warn("Hia model => check if bvaccine = true => dosesgiven = 3.")
    warn("Hia model => √ ageplusplus can be absorbed into the daily lattice update function")
    warn("Hia model => √ presymptomatic is also infectious - reduction 50% - done preliminary")
    warn("Hia model => √ if invasive before, always mark as false")   
    warn("Hia model => Implement death in invasive compartment")
    warn("Hia model => √ Use four beta values instead of one")
    warn("Hia model => think of a way to implement changing age distribution")
    warn("Hia model => algorithm to track a human")
    warn("Hia model => profile main() and check bottlenecks")
    warn("Hia model => verify age brackets for contact matrix")
    warn("Hia model => clean up cmt-ag variables in main()")  
end

function track(h::Human, i::Int64)
    println("tracking human: $i")
    println("...health")
    println("       cur/swap: $(h.health)/$(h.swap)")
    println("       path:     $(h.path)")
    println("       inv:      $(h.inv)")
    println("       plvl:     $(h.plvl)")
    println("...demographics")
    println("       age/sex:  $(h.age) / $(h.gender)")
    println("       age(yrs): $(h.age/365)")    
    println("       meetcnt:  $(h.meetcnt)")
    println("...model (_instate) variables")
    println("       time:     $(h.timeinstate)")
    println("       expiry:   $(h.statetime)")
    println("...vaccine")
    println("       primary:  $(h.pvaccine)")
    println("       booster:  $(h.bvaccine)")
    println("       # doses:  $(h.dosesgiven)")
    
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
            elseif h.plvl > 0.50 
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
            # age > 5, and a susceptible - (either susceptible by birth or susceptible by recovery)
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



function agegroup(age::Integer)
    ## these agegroups only applicable for contacts - used in function dailycontacts()
    @match age begin
        0:365       => 1  # 0 - 1  ## completed first year
        366:1460    => 2  # 2 - 4  ## completed upto 4 years
        1461:3285   => 3  # 5- 10  ## starting 5th year, completed 10 years
        3285:36501  => 4  # 10+
        _           => error("Hia Model => age too large in agegroup()")
    end
end

function statetime(state::HEALTH, P::HiaParameters)
    ## this returns the statetime for everystate
    ## match dosnt work with ENUMS, convert to Int
    ##  @enum HEALTH SUSC=1 LAT=2 PRE=3 SYMP=4 INV=5 REC=6 DEAD=7 UNDEF=0
    st = 0 ## return variable
    @match Symbol(state) begin
        :SUSC  => st = typemax(Int32)  ## no expiry for suscepitble
        :LAT   => 
                begin
                    d = LogNormal(P.latentshape, P.latentscale)
                    st = max(P.latentmin, min(Int(ceil(rand(d))), P.latentmax))
                end
        :CAR   => st = rand(P.carriagemin:P.carriagemax) ## fixed 50 days for carriage?
        :PRE   => st = P.presympmin
        :SYMP  => 
                begin
                    d = Poisson(P.symptomaticmean)
                    st = max(P.symptomaticmin, min(rand(d), P.symptomaticmax)) + P.infaftertreatment
                end
        :INV   => st = rand(P.invasivemin:P.invasivemax)
        :REC   => st = rand(P.recoveredmin:P.recoveredmax)
        :DEAD  => error("Hia model =>  not implemented")        
        _   => throw("Hia model => statetime passed in non-health enum")
    end
    return st
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

function insertrandom(h::Array{Human}, P::HiaParameters, s::HEALTH)
    i = rand(1:P.gridsize) ## select a random human
    # set the swap and run the update functiona manually
    setswap(h[i], s)    
    swap(h[i], P)
    return i
end
# 