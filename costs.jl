### cost and resource calculation 



function dailycosts(x::Human, P::HiaParameters, C::CostCollection)
    rowid = x.id
    colid = Int(x.health)
    C.costmatrix[rowid, colid] += statecost(x, P)
    ## todo: add medivac costs    
end

function statecost(x::Human, P::HiaParameters)
    cc = 0 #calculated cost
    state = x.health
    @match Symbol(state) begin
        :SUSC => cc = 0 # no cost for susceptible
        :LAT  => cc = 0 # no cost for latent
        :CAR  => cc = 0 # no cost for carriage 
        :SYMP => 
            begin
               cc = P.cost_physicianvisit + P.cost_antibiotics
               cc = x.statetime * cc 
            end
        :INV  => 
            begin
                t = hospitalinfo(x, P)[2]  ## function returns a tuple, [1] is length of stay, [2] is cost of hospital stay per night. 
                m = x.agegroup_beta == 1 ? P.cost_medivac : 0
                s = 0  ## cost of sequlae
                cc = (t*x.statetime) + m + s
            end
        :REC  => cc = 0 # no cost for carriage         
        _     => cc = 0
    end        
    return cc
end