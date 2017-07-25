### cost and resource calculation 

function processcosts(prefix, numofsims)
    info("starting reading of hdf5/jld files using pmap")
    a = pmap(1:numofsims) do x
        filename = string(prefix, x, ".jld")
        return load(filename)["costs"]  
    end
    info("pmap finished, returning function. ")
    m = zeros(Int64, numofsims, 8)  ## 8 columns for health status
    for i = 1:numofsims
        m[i, :] = sum(a[i].costmatrix, 1)
    end
    writedlm("costs.dat",  m)
    return a; 
end

function dailycosts(x::Human, P::HiaParameters, C::CostCollection, t)
    rowid = x.id
    colid = Int(x.health)
    C.costmatrix[rowid, colid] += statecost(x, P)
    ## todo: add medivac costs    
end

function statecost(x::Human, P::HiaParameters)
    totalphys    = 0 ## physician
    totalhosp    = 0 ## hospital cost 
    totalmed     = 0 ## medivac cost   
    totalseqmaj  = 0 ## sequlae cost 
    totalseqmin  = 0 ## sequlae cost 

    state = x.health
    @match Symbol(state) begin
        :SUSC => cc = 0 # no cost for susceptible
        :LAT  => cc = 0 # no cost for latent
        :CAR  => cc = 0 # no cost for carriage 
        :SYMP => 
            begin
               totalphys = P.cost_physicianvisit + P.cost_antibiotics               
            end
        :INV  => 
            begin
                totalhosp = hospitalcost(x, P) * x.statetime  ## total hospital cost = daily cost * time in hospital
                totalmed  = x.agegroup_beta == 1 ? P.cost_medivac : 0
                ## invtype should've been set.. (in tests.. check if x.invtype == NOINV when person is invasive)
                if x.invtype != MENNOSEQ  x.invtype != PNEU && x.invtype != NPNM  
                    ## the person has either major/minor sequlae. 
                    s = string(x.invtype)[(end - 2):end]
                    if s == "MAJ"
                        totalseqmaj = P.cost_meningitis_major * (x.agedeath/365 - x.age/365)
                    elseif s == "MIN"
                        totalseqmin = 0
                    else 
                        error("what?")
                    end
                end                            
            end
        :REC  => cc = 0 # no cost for carriage         
        _     => cc = 0
    end        
    return totalhosp + totalmed + totalseq
end

