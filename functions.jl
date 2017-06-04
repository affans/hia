
function todo()
    warn("Hia model => calculate probability distribution for death, and implement code")
    warn("Hia model => update pathtaken() when vaccine is implemented")
    
end

function carriageprobs(pa::Int64, P::HiaParameters)
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

function pathtaken(h::Human, P::HiaParameters)
    ## calculates which path they will take based on a decision tree
    st = 0
    if h.health == SUSC
        if h.age < 1825 # less than 5
            st = 1
        elseif (h.age >= 1825 && h.age < 3650) || h.age >= 21900 ## 5 - 10  or 60+           
            st = 2
        else
            st = 3
        end
    elseif h.health == REC 
        st = 4        
    end
    h.path = st
    return st
end



function agegroup(age::Int64)
    ## these agegroups only applicable for contacts - used in function dailycontacts()
    @match age begin
        0:365       => 1
        366:1460    => 2
        1461:3285   => 3
        3285:36501  => 4
        _           => error("Hia Model => age too large in agegroup()")
    end
end

function statetime(state::HEALTH, P::HiaParameters)
    ## this returns the statetime for everystate
    ## match dosnt work with ENUMS, convert to Int
    ##  @enum HEALTH SUSC=1 LAT=2 PRE=3 SYMP=4 INV=5 REC=6 DEAD=7 UNDEF=0
    st = 0 ## return variable
    @match Symbol(state) begin
        :SUSC  => st = typemax(Int64)  ## no expiry for suscepitble
        :LAT   => 
                begin
                    d = LogNormal(P.latentshape, P.latentscale)
                    st = max(P.latentmin, min(Int(floor(rand(d))), P.latentmax))
                end
        :CAR   => st = rand(P.carriagemin:P.carriagemax) ## fixed 50 days for carriage?
        :PRE   => st = P.presympmin
        :SYMP  => 
                begin
                    d = Poisson(3)
                    st = max(P.symptomaticmin, min(rand(d), P.symptomaticmax)) + P.infaftertreatment
                end
        :INV   => st = 6
        :REC   => st = rand(P.recoveredmin:P.recoveredmax)
        :DEAD  => error("Hia model =>  not implemented")        
        _   => throw("Hia model => statetime passed in non-health enum")
    end
    return st
end

