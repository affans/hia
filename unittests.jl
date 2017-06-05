using Base.Test


function test_ageplusplus()
    ##initialize a system
    P = HiaParameters(gridsize = 100000)
    humans = Array{Human}(P.gridsize);
    initialize(humans, P)
    demographics(humans, P)

    ageplusplus(humans, P)
    timeplusplus(humans, P)
    track(humans[1], 1)
    
    @time dailycontact(humans, P)
    track(humans[1], 1)
    

    setswap(humans[1], LAT)
    track(humans[1], 1)
    @time update(humans, P)
    track(humans[1], 1)
    


end