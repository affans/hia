function probofcarriage()
    error("HiaModel => Not implemented")
end

function agegroup(age::Int64)
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

