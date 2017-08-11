### cost and resource calculation 


function symptomatic_cost(x::Human, P::HiaParameters, st)
    sys_time = Int(floor(st/365)) ## get year value
    totalphys    = 0 ## physician
    totalhosp    = 0 ## hospital cost 
    totalmed     = 0 ## medivac cost   
    totalseqmaj  = 0 ## sequlae cost 
    totalseqmin  = 0 ## sequlae cost 
    ## test scenario: check this is between 1 - 10
    totalphys = P.cost_physicianvisit
   
    return Int(round(totalphys)), Int(round(totalhosp)), Int(round(totalmed)), Int(round(totalseqmaj)), Int(round(totalseqmin))
end

function invasive_good(x::Human, P::HiaParameters, st)
    ## invasive disease - no death, no disability (ie MENNOSEQ, PNEU, NPNM )
    ## invasive disease - with death
    sys_time = Int(floor(st/365)) ## get year value
    totalphys    = 0 ## physician
    totalhosp    = 0 ## hospital cost 
    totalmed     = 0 ## medivac cost   
    totalseqmaj  = 0 ## sequlae cost 
    totalseqmin  = 0 ## sequlae cost 
    
    totalhosp = hospitalcost(x, P) * x.statetime  ## total hospital
    if x.agegroup_beta == 1 
        totalmed = P.cost_medivac
    end
    return Int(round(totalphys)), Int(round(totalhosp)), Int(round(totalmed)), Int(round(totalseqmaj)), Int(round(totalseqmin))
end


function invasive_major(x::Human, P::HiaParameters, st)
    ## invasive disease - with major disability 
    sys_time = Int(floor(st/365)) ## get year value
    totalphys    = 0 ## physician
    totalhosp    = 0 ## hospital cost 
    totalmed     = 0 ## medivac cost   
    totalseqmaj  = 0 ## sequlae cost 
    totalseqmin  = 0 ## sequlae cost 

    ## how much money is needed today to cover their future hospital cost
    totalhosp = hospitalcost(x, P) * x.statetime  ## 
    
    ## disability major is a yearly cost until death.. use their expectancy to figure this out
    agediff = Int(floor((x.expectancy - x.age)/365))     ## in terms of years.
    ## the cost of major sequlae is 109664/year..    
    totalseqmaj = sum([P.cost_meningitis_major/(1+P.discount_cost)^i for i=1:agediff])
    
    ## medivac
    if x.agegroup_beta == 1         
        totalmed = P.cost_medivac        
    end
    return Int(round(totalphys)), Int(round(totalhosp)), Int(round(totalmed)), Int(round(totalseqmaj)), Int(round(totalseqmin))
end

function invasive_minor(x::Human, P::HiaParameters, st)
    ## invasive disease - with major disability 
    sys_time = Int(floor(st/365)) ## get year value
    totalphys    = 0 ## physician
    totalhosp    = 0 ## hospital cost 
    totalmed     = 0 ## medivac cost   
    totalseqmaj  = 0 ## sequlae cost 
    totalseqmin  = 0 ## sequlae cost 

    ## how much money is needed today to cover their future hospital cost
    totalhosp = hospitalcost(x, P) * x.statetime  ## 

    ## medivac
    if x.agegroup_beta == 1         
        totalmed = P.cost_medivac        
    end
    
    ## get age of death

    if x.expectancy > 8030 ## age of death is past 22 years old
        if x.age <= 730 ## 0 - 2 
            ## fixed assessment cost 
            A = P.cost_minor_infant
            ## four years of preschool
            B = sum([P.cost_minor_preschool/(1+P.discount_cost)^i for i=1:4])
            ## school for 18 years, per year
            C = sum([P.cost_minor_school/(1+P.discount_cost)^i for i=1:12])
            ## adult life training cost -- happens almost 18 years later so discount accordingly.
            D = P.cost_minor_adult
            totalseqmin = A + B + C + D
        end

        if x.age > 730 && x.age <= 2190 ## 2 - 6 
            ## remaining years of preschool out of 4 years..
            rmy = Int(ceil(4 - (x.age - 730)/365))
            B = sum([P.cost_minor_preschool/(1+P.discount_cost)^i for i=1:rmy])
            ## school for 18 years, per year
            C = sum([P.cost_minor_school/(1+P.discount_cost)^i for i=1:12])
            ## adult life training cost
            D = P.cost_minor_adult
            totalseqmin = B + C + D 
        end

        if x.age > 2190 && x.age <= 6570 ## 6 - 18
            ## only school costs..  remaining school costs.. 12 total years
            rmy = Int(ceil(12 - (x.age - 2190)/365)) 
            C = sum([P.cost_minor_school/(1+P.discount_cost)^i for i=1:rmy])
             
            ## adult life training cost
            D = P.cost_minor_adult
            totalseqmin = C + D          
        end   
        if x.age > 7300 
            D = P.cost_minor_adult
            totalseqmin = D
        end        
    end
    return Int(round(totalphys)), Int(round(totalhosp)), Int(round(totalmed)), Int(round(totalseqmaj)), Int(round(totalseqmin))
end

function collectcosts(x::Human, P::HiaParameters, st::Int64)
    if x.health == SYMP
        return symptomatic_cost(x, P, st)
    elseif x.health == INV
        if x.invdeath == true 
            return invasive_good(x, P, st)
        else 
            ## invdeath == false, so invtype must be set
            if x.invtype != MENNOSEQ && x.invtype != PNEU && x.invtype != NPNM
                s = string(x.invtype)[(end - 2):end]
                if s == "MAJ"
                    return invasive_major(x, P, st)
                elseif s == "MIN"
                    return invasive_minor(x, P, st)          
                else 
                    error("Hia error => invtype is not set properly, when trying to calculate costs.")
                end 
            else
                return invasive_good(x, P, st)
            end
        end
    end   
    ## physician/hospital/medivac/major/minor
    return 0, 0, 0, 0, 0
end