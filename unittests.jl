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
    find(x -> x.health != SUSC, humans)

    setswap(humans[1], LAT)
    track(humans[1], 1)
    @time update(humans, P)
    track(humans[1], 1)
    
    initialize(humans, P)
    demographics(humans, P)
    
    
    t = findfirst(x -> x.age > 21900, humans)

    primary(humans[t], P, 3)
    booster(humans[t], P)
    track(humans[t], 2)

    setswap(humans[t], REC)
    @time swap(humans[t], P)
    track(humans[t], 2)

    setswap(humans[t], REC)
    @time swap(humans[t], P)
    track(humans[t], 1)

    
    
    humans[3].timeinstate = 1708
    timeplusplus(humans, P)
    track(humans[3], 1)
    @time swap(humans[3], P)

    setswap(humans[3], LAT)
    @time swap(humans[3], P)
    track(humans[3], 1)


    
end




function m()
    myvec = zeros(Int64, 10)
    function t1()
        for i = 1:length(myvec)
            myvec[i] += 1
        end
    end   
    t1()
    return myvec
end