
function primary(h::Human)
  ## this function turns on primary vaccination  
  h.pvaccine = rand() < 0.95 ? true : false
end

function dose(h::Human)
  ## this function applies a dose 
  if h.pvaccine
    h.dosesgiven += 1
    if h.dosesgiven > 3 
      error("Hia model => more than three primary doses given")
    end
    h.plvl = protection(h)  ## reapply protection level. 
  end
end

function booster(h::Human)
    ## vaccine changes protection level
    ## turn on the primary variable
    if h.dosesgiven == 3
        h.bvaccine = rand() < 0.90 ? true : false
        h.plvl = protection(h)
    end
end