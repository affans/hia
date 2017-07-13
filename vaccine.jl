
function dose(h::Human)
  ## this function applies a dose 
  if h.pvaccine
    h.dosesgiven += 1
    if h.dosesgiven > 3 
      error("Hia model => more than three primary doses given")
    end
  end
  return nothing
end



function vcc(x::Human, P::HiaParameters)
    if x.age == P.doseonetime 		
        ## Its time for the first dose, 
        ## first check if this person is even eligible for vaccine 
        x.pvaccine = rand() <= P.primarycoverage ? true : false
        if x.pvaccine
            dose(x)    ## increase dose counter up by one. 
            ## vaccine induced protection time is relative to their age... 
            ## so if age = 365 and sampled time is 2 years, then expiry would be 365 + 2 years.. this is to save a variable and keeping track of yet another time variable.
            x.vaccineexpirytime = x.age + rand(P.primarytimemin:P.primarytimemax)
        end
        x.plvl = protection(x)
    elseif x.age == P.dosetwotime || x.age == P.dosethreetime 		
        dose(x)		
        x.plvl = protection(x)  ## reapply protection level. 
    elseif x.age == P.boostertime		
        if x.dosesgiven == 3
            x.bvaccine = rand() <= P.boostercoverage ? true : false
            if x.bvaccine
                ## vaccine induced protection time is relative to their age... 
                ## so if age = 365 and sampled time is 2 years, then expiry would be 365 + 2 years.. this is to save a variable and keeping track of yet another time variable.
                x.vaccineexpirytime = x.age + rand(P.boostertimemin:P.boostertimemax)
            end
        end 
        x.plvl = protection(x)	
    end
end