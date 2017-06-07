function vaccinecheck(h::Array{Human}, P::HiaParameters)

end

function primary(h::Human)
  ## this function turns on primary vaccination
  h.pvaccine = true
end

function dose(h::Human)
  ## this function applies a dose 
  if h.pvaccine
    h.dosesgiven += 1
    if h.dosesgiven > 3 
      error("Hia model => more than three primary doses given")
    end
    h.plvl = protection(h)
  end
end

function booster(h::Human, P::HiaParameters)
    ## vaccine changes protection level
    ## turn on the primary variable
    if h.dosesgiven == 3
        h.bvaccine = true
        h.plvl = protection(h)
    else    
        warn("can not turn on booster - setting bvaccine = false")
        h.bvaccine = false
    end    
end