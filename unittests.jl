## Unit tests - to be implemented

## if invasive compartment, then check invtype is set properly. 

P = HiaParameters()
M = ModelParameters()
M.initializenew = true
h = setuphumans(1, P, M)

function time_app(humans, P, M)
    for i in eachindex(humans)
       dailycontact(humans[i], P, ag1, ag2, ag3, ag4, n, f, s, t)
    end
end


function test_hospitalinfo()
    h[1].age = 240
    h[2].age = 1000
    h[3].age = 3500
    h[4].age = 7000
    h[5].age = 22000
    h[6].age = 32000

    @time l, c = hospitalinfo(h[1], P)
    @test length(findin(10:14, l)) == 1
end