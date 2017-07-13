## Unit tests - to be implemented

## if invasive compartment, then check invtype is set properly. 

using Base.Test

P = HiaParameters()
M = ModelParameters()
M.initializenew = true


@testset "Protection Levels and Vaccine" begin
  ## <5, >5 natural immunity, no vaccine
  h = setuphumans(1, P, M)[1];
  h.swap = SUSC;
  swap(h, P); h.swap = UNDEF    
  h.age = 265;
  @test protection(h) == 0.0
  h.age = 16500;
  @test protection(h) == 0.5

  ## natural immunity from sickness - all scenarios
  h = setuphumans(1, P, M)[1];
  h.swap = LAT;   ## need to go through latent to increase the counter
  swap(h, P); h.swap = UNDEF;
  h.swap = REC; 
  swap(h, P); h.swap = UNDEF;
  h.age = 265;  
  @test protection(h) == 0.9  ## test <5 years
  h.age = 16500;
  @test protection(h) == 0.9  ## test >5 years

  ## Vaccine/Protection Simultaneously.
  h = setuphumans(1, P, M)[1];  
  h.age = P.doseonetime
  P.primarycoverage = 1.0 ## force primary coverage
  vcc(h, P)  ## first dose given, h.vaccineexpirytime should be set.. save this value
  tempvalue = h.vaccineexpirytime
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 1
  @test protection(h) == h.plvl  ## check if plvl is correctly set after 
  @test h.vaccineexpirytime >= (h.age + (2*365)) &&  h.vaccineexpirytime <= (h.age + (5*365))
  @test h.vaccineexpirytime > h.age
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  @test protection(h) == 0.5
  
  h.age = P.dosetwotime 
  vcc(h, P)  ## second dose given
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 2
  @test protection(h) == h.plvl
  @test h.vaccineexpirytime == tempvalue  ## vaccine expiry time should not change as doses are given
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  @test protection(h) == 0.5
  
  h.age = P.dosethreetime
  vcc(h, P)  ## third dose given
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 3
  @test protection(h) == h.plvl
  @test h.vaccineexpirytime == tempvalue
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  @test protection(h) == 0.5

  h.age = P.boostertime
  P.boostercoverage = -1.0  
  vcc(h, P) #booster time
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 3
  @test protection(h) == h.plvl
  @test h.vaccineexpirytime == tempvalue
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  @test protection(h) == 0.5
  
  h.age = P.boostertime
  P.boostercoverage = 1.0  
  vcc(h, P) 
  @test h.pvaccine == true 
  @test h.bvaccine == true
  @test h.dosesgiven == 3
  @test h.plvl >= 0.85 && h.plvl <= 0.95
  @test h.vaccineexpirytime != tempvalue
  @test h.vaccineexpirytime >= (h.age + (6*365)) &&  h.vaccineexpirytime <= (h.age + (10*365))
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  @test protection(h) == 0.5

  ## the "h" variable has now recieved entire vaccine series (primary and booster)
  h.age = P.boostertime + 1 ## and now one day older, still <5
  ## shock the system - make this person sick
  h.swap = LAT;   ## need to go through latent to increase the counter
  swap(h, P); h.swap = UNDEF;
  h.swap = REC; 
  swap(h, P); h.swap = UNDEF;
  h.swap = SUSC 
  swap(h, P); h.swap = UNDEF 
  @test protection(h) == 0.5 ## test <5 years
  @test protection(h) == h.plvl
 

end
