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

function symptomatic_cost(x::Human, P::HiaParameters, st)
    sys_time = Int(ceil(st/365)) ## get year value
    ## test scenario: check this is between 1 - 10
    futurevalue = P.cost_physicianvisit*(1+P.discount_cost)^sys_time
    return futurevalue
end

function invasive_good(x::Human, P::HiaParameters, st)
    ## invasive disease - no death, no disability (ie only meningitis)
    ## OR 
    ## invasive disease - with death, no disability (ie only meningitis)

    sys_time = Int(ceil(st/365)) ## get year value
    totalphys    = 0 ## physician
    totalhosp    = 0 ## hospital cost 
    totalmed     = 0 ## medivac cost   
    totalseqmaj  = 0 ## sequlae cost 
    totalseqmin  = 0 ## sequlae cost 
    ##calcuation -- future value of the costs today...
    totalhosp = hospitalcost(x, P)*(1 + P.discount_cost)^sys_time * x.statetime  ## total hospital
    if x.agegroup_beta == 1 
        totalmed = P.cost_medivac*(1+P.discount_cost)^sys_time
    end
    return totalphys, totalhosp, totalmed, totalseqmaj, totalseqmin
end


function invasive_major(x::Human, P::HiaParameters, st)
    ## invasive disease - with major disability 
    sys_time = Int(ceil(st/365)) ## get year value
    totalphys    = 0 ## physician
    totalhosp    = 0 ## hospital cost 
    totalmed     = 0 ## medivac cost   
    totalseqmaj  = 0 ## sequlae cost 
    totalseqmin  = 0 ## sequlae cost 

    ## how much money is needed today to cover their future hospital cost
    totalhosp = hospitalcost(x, P)*(1 + P.discount_cost)^sys_time * x.statetime  ## 
    
    ## the cost of major sequlae today is 109664/year..
    ## at the time of event, its not 109664/year.. its whatever the value is in the future that is worth 109664 today. 
    fvm = P.cost_meningitis_major*(1 + P.discount_cost)^sys_time

    ## now fvm is a yearly cost.. we need to sample how long this person will live.
    dd = rand(distribution_death(x.age))
    diff = dd*365 - x.age ## get the difference
    totalseqmaj = sum([fvm/(1 + P.discount_cost)^sys_time for i = 1:diff])
    ## medivac???
    return totalphys, totalhosp, totalmed, totalseqmaj, totalseqmin
end

function invasive_minor(x::Human, P::HiaParameters, st)
    ## invasive disease - with major disability 
    sys_time = Int(ceil(st/365)) ## get year value
    totalphys    = 0 ## physician
    totalhosp    = 0 ## hospital cost 
    totalmed     = 0 ## medivac cost   
    totalseqmaj  = 0 ## sequlae cost 
    totalseqmin  = 0 ## sequlae cost 

    ## how much money is needed today to cover their future hospital cost
    totalhosp = hospitalcost(x, P)*(1 + P.discount_cost)^sys_time * x.statetime  ## 
    
    ## get age of death
    agd = rand(distribution_death(x.age))*365
    if agd > 8030 ## age of death is past 22 years old
        if x.age <= 730 ## 0 - 2 
            ## fixed assessment cost 
            assess_fv = P.cost_minor_infant*(1 + P.discount_cost)^sys_time
            ## four years of preschool
            preschool_fv = (4*P.cost_minor_preschool)*(1 + P.discount_cost)^sys_time
            ## bring the school value to the time of even
            scfv = P.cost_minor_school*(1 + P.discount_cost)^sys_time
            school_pulled = sum([scfv/(1 + P.discount_cost)^i for i = 1:12]) ## until they turn 18
            ## adult life training cost
            totalseqmin = assess_fv + preschool_fv + school_pulled
        end

        if x.age > 730 && x.age <= 2190 ## 2 - 6 
            ## remaining years of preschool out of 4 years..
            rmy = Int(ceil(4 - (x.age - 730)/365))
            preschool_fv = (rmy*P.cost_minor_preschool)*(1 + P.discount_cost)^sys_time
            ## bring the school value to the time of even
            scfv = P.cost_minor_school*(1 + P.discount_cost)^sys_time
            school_pulled = sum([scfv/(1 + P.discount_cost)^i for i = 1:12]) ## until they turn 18
            ## adult life training cost
            totalseqmin = preschool_fv + school_pulled            
        end

        if x.age > 2190 && x.age <= 6570 ## 6 - 18
            ## only school costs..  remaining school costs.. 12 total years
            rmy = Int(ceil(12 - (x.age - 2190)/365)) 
            ## bring the school value to the time of event
            scfv = P.cost_minor_school*(1 + P.discount_cost)^sys_time
            school_pulled = sum([scfv/(1 + P.discount_cost)^i for i = 1:rmy]) ## until they turn 18
            ## adult life training cost
            totalseqmin = school_pulled            
        end
    end



end