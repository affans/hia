
function dose(h::Human)
  ## this function applies a dose 
  if h.pvaccine
    h.dosesgiven += 1
    if h.dosesgiven > 3 
      error("Hia model => more than three primary doses given")
    end
    h.plvl = protection(h)  ## reapply protection level. 
  end
  return nothing
end

function booster(h::Human)
    ## vaccine changes protection level
    ## turn on the primary variable
    if h.dosesgiven == 3
        h.bvaccine = rand() < 0.90 ? true : false
        h.plvl = protection(h)
    end
    return nothing
end


function vcc(x::Human, P::HiaParameters)
  if x.age == P.doseonetime 		
      ## turn on primary vaccine
      x.pvaccine = rand() < 0.95 ? true : false
      dose(x)		
  elseif x.age == P.dosetwotime || x.age == P.dosethreetime 		
      dose(x)		
  elseif x.age == P.boostertime		
      booster(x)		
  end
end