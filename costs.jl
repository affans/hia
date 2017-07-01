### cost and resource calculation 

type Costs
    costmatrix::Matrix{Int64}
    Costs(size::Int64) = new(zeros(Int64, size, size))
end

function statecost(state::HEALTH)
    cc = 0 #calculated cost
    @match Symbol(state) begin
        :SUSC => cc = 0 # no cost for susceptible
        :LAT  => cc = 0 # no cost for latent
        :CAR  => cc = 0 # no cost for carriage 
    

                
        _     => throw("Hia Model => invalid health state passed to statecost()")


    end        
    
end