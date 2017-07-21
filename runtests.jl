## Unit tests - to be implemented

## if invasive compartment, then check invtype is set properly. 

using Base.Test



@testset "State Times" begin 
  P = HiaParameters()
  M = ModelParameters()
  M.initializenew = true

  h = setuphumans(1, P, M)[1];
  h.swap = SUSC; swap(h, P); h.swap = UNDEF 
  @test statetime(h, P) == typemax(Int64)
  h.swap = LAT; swap(h, P); h.swap = UNDEF 
  @test statetime(h, P) >= P.latentmin  #should loop these
  @test statetime(h, P) <= P.latentmax
  h.swap = CAR; swap(h, P); h.swap = UNDEF 
  @test statetime(h, P) >= P.carriagemin  #should loop these
  @test statetime(h, P) <= P.carriagemax
  h.swap = SYMP; swap(h, P); h.swap = UNDEF 
  @test statetime(h, P) >= P.symptomaticmin  #should loop these
  @test statetime(h, P) <= P.symptomaticmax
  h.swap = REC; swap(h, P); h.swap = UNDEF 
  @test statetime(h, P) >= P.recoveredmin  #should loop these
  @test statetime(h, P) <= P.recoveredmax  
end

@testset "Protection" begin
  ## note: to test protection levels, they need to go through swap(), or vcc() function...
  ## <5, >5; natural immunity; no vaccine
  P = HiaParameters()
  M = ModelParameters()
  M.initializenew = true

  ## <5, >5; natural immunity; no vaccine
  h = setuphumans(1, P, M)[1];    
  h.age = 265;
  h.swap = SUSC;
  swap(h, P); h.swap = UNDEF 
  @test protection(h) == 0.0
  @test protection(h) == h.plvl
  h.age = 16500;
  h.swap = SUSC;
  swap(h, P); h.swap = UNDEF
  @test protection(h) == 0.5
  @test h.plvl == protection(h)

    ## high immunity in recovery/immunity after recovery  
  h = setuphumans(1, P, M)[1];
  h.swap = LAT;   ## need to go through latent to increase the counter
  swap(h, P); h.swap = UNDEF;
  
  h.age = 265;   
  h.swap = REC; swap(h, P); h.swap = UNDEF;  ## human now in recovery class
  @test protection(h) == 0.95  
  @test h.plvl == protection(h)
  
  h.age = 16500;
  h.swap = REC; swap(h, P); h.swap = UNDEF;  ## human now in recovery class
  @test protection(h) == 0.95  ## test >5 years
  @test h.plvl == protection(h)

  h.age = 265;  ## test <5 years
  h.swap = SUSC; swap(h, P); h.swap = UNDEF; ## make human susc again, after recovery.. so they've been sick now..  
  @test protection(h) == 0.5  
  @test h.plvl == protection(h)

  h.age = 16500; ## test >5 years
  h.swap = SUSC; swap(h, P); h.swap = UNDEF; ## make human susc again, after recovery.. so they've been sick now..    
  @test protection(h) == 0.5  
  @test h.plvl == protection(h)


end

@testset "Vaccine" begin
  ## note: to test protection levels, they need to go through swap(), or vcc() function...  
  P = HiaParameters()
  M = ModelParameters()
  M.initializenew = true

  h = setuphumans(1, P, M)[1];  
  h.age = P.doseonetime
  P.primarycoverage = 1.0 ## force primary coverage
  vcc(h, P)  ## first dose given, h.vaccineexpirytime should be set.. save this value
  tempvalue = h.vaccineexpirytime
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 1
  @test protection(h) == 0.5
  @test protection(h) == h.plvl  ## check if plvl is correctly set after 
  @test h.vaccineexpirytime >= (h.age + (2*365)) &&  h.vaccineexpirytime <= (h.age + (5*365))
  @test h.vaccineexpirytime > h.age
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  vcc(h, P)
  @test protection(h) == 0.5
  @test h.plvl == protection(h)
  
  h.age = P.dosetwotime 
  vcc(h, P)  ## second dose given
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 2
  @test protection(h) == h.plvl
  @test h.vaccineexpirytime == tempvalue  ## vaccine expiry time should not change as doses are given
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  vcc(h, P)
  @test protection(h) == 0.5
  @test h.plvl == protection(h)
  
  h.age = P.dosethreetime
  vcc(h, P)  ## third dose given
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 3
  @test protection(h) == h.plvl
  @test h.vaccineexpirytime == tempvalue
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  vcc(h, P)
  @test protection(h) == 0.5
  @test h.plvl == protection(h)

  ## check error if doses given > 3..
  h.age = P.dosethreetime
  @test_throws ErrorException vcc(h, P)  


  h.age = P.boostertime
  P.boostercoverage = -1.0  
  vcc(h, P) #booster time
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 3
  @test protection(h) == h.plvl
  @test h.vaccineexpirytime == tempvalue
  h.age = h.vaccineexpirytime + 1  ## natural immunity after time of expiry
  vcc(h, P)
  @test protection(h) == 0.5
  @test h.plvl == protection(h)
  
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
  vcc(h, P)
  @test protection(h) == 0.5
  @test h.plvl == protection(h)

  ## the "h" variable has now recieved entire vaccine series (primary and booster)
  h.age = P.boostertime + 1 ## and now one day older after booster, still <5
  ## shock the system - make this person sick
  h.swap = LAT; swap(h, P); h.swap = UNDEF;
  h.swap = REC; swap(h, P); h.swap = UNDEF; 
  h.swap = SUSC; swap(h, P); h.swap = UNDEF   
  @test protection(h) == 0.5 ## test <5 years
  @test protection(h) == h.plvl 

end

@testset "Paths" begin
  P = HiaParameters()
  M = ModelParameters()
  M.initializenew = true

  # getting sick, <5, no immunity/vaccine, previous infection
  h = setuphumans(1, P, M)[1];  ## default susceptible human
  h.age = 365 
  @test h.path == 0 
  h.swap = SUSC; swap(h, P); h.swap = UNDEF 
  @test h.path == 0     
  h.swap = LAT; swap(h, P); h.swap = UNDEF    ## make person sick
  @test h.path == 1
  h.swap = REC; swap(h, P); h.swap = UNDEF    ## make person recovered
  h.swap = SUSC; swap(h, P); h.swap = UNDEF   ## make person susceptible
  h.swap = LAT; swap(h, P); h.swap = UNDEF    ## make person sick
  @test h.path == 7  

  # getting sick, >5, no immunity/vaccine, previous infection
  h = setuphumans(1, P, M)[1];  ## default susceptible human
  h.age = 16500
  @test h.path == 0 
  h.swap = SUSC; swap(h, P); h.swap = UNDEF 
  @test h.path == 0     
  h.swap = LAT; swap(h, P); h.swap = UNDEF 
  @test h.path == 7
  h.swap = REC; swap(h, P); h.swap = UNDEF    ## make person recovered
  h.swap = SUSC; swap(h, P); h.swap = UNDEF   ## make person susceptible
  h.swap = LAT; swap(h, P); h.swap = UNDEF    ## make person sick
  @test h.path == 7  

  ## getting sick while in recovery, <5 
  h = setuphumans(1, P, M)[1];  ## default susceptible human
  h.age = 365
  h.swap = REC; swap(h, P); h.swap = UNDEF 
  @test h.path == 0     
  h.swap = LAT; swap(h, P); h.swap = UNDEF 
  @test h.path == 6  

  ## getting sick while in recovery, >5
  h = setuphumans(1, P, M)[1];  ## default susceptible human
  h.age = 16500
  h.swap = REC; swap(h, P); h.swap = UNDEF 
  @test h.path == 0     
  h.swap = LAT; swap(h, P); h.swap = UNDEF 
  @test h.path == 6  

  ## getting sick after vaccine primary dose 1
  h = setuphumans(1, P, M)[1];  ## default susceptible human
  h.age = P.doseonetime
  P.primarycoverage = 1.0 ## force primary coverage
  vcc(h, P)  ## first dose given, h.vaccineexpirytime should be set.. save this value
  @test h.path == 0   ## check default path
  h.swap = LAT; swap(h, P); h.swap = UNDEF  
  @test h.path == 2

  ## getting sick after vaccine primary dose 2
  h.age = P.dosetwotime 
  vcc(h, P)  ## second dose given
  h.swap = REC; swap(h, P); h.swap = UNDEF    ## make person recovered
  h.swap = SUSC; swap(h, P); h.swap = UNDEF   ## make person susceptible
  h.carcnt = 0;  h.latcnt = 0; 
  h.symcnt = 0;  h.invcnt = 0; ## set these counters to zero, otherwise we have a "previous infection" path
  h.swap = LAT; swap(h, P); h.swap = UNDEF  
  @test h.path == 3

  ## getting sick after vaccine primary dose 3
  h.age = P.dosethreetime 
  vcc(h, P)  ## third dose given
  h.swap = REC; swap(h, P); h.swap = UNDEF    ## make person recovered
  h.swap = SUSC; swap(h, P); h.swap = UNDEF   ## make person susceptible
  h.carcnt = 0;  h.latcnt = 0; 
  h.symcnt = 0;  h.invcnt = 0; ## set these counters to zero, otherwise we have a "previous infection" path
  h.swap = LAT; swap(h, P); h.swap = UNDEF  
  @test h.path == 4

  ## getting sick after vaccine booster
  h.age = P.boostertime
  P.boostercoverage = 1.0  ## force booster
  vcc(h, P)  ## third dose given
  h.swap = REC; swap(h, P); h.swap = UNDEF    ## make person recovered
  h.swap = SUSC; swap(h, P); h.swap = UNDEF   ## make person susceptible
  h.carcnt = 0;  h.latcnt = 0; 
  h.symcnt = 0;  h.invcnt = 0; ## set these counters to zero, otherwise we have a "previous infection" path
  h.swap = LAT; swap(h, P); h.swap = UNDEF  
  @test h.path == 5
end

## check if invtype/invdeath is always set in INV class

@testset "Invasive" begin

  ## test if sequale enums end with MAJ or MIN (for the first 14 of them.. because we use this information in the costs calculation)  
  for i = 1:7
    @test string(INVSEQ(i))[(end - 2):end] == "MAJ"
  end
  for i = 8:14
    @test string(INVSEQ(i))[(end - 2):end] == "MIN"
  end


end