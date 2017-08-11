# Unit tests - to be implemented

# if invasive compartment, then check invtype is set properly. 

include("main.jl")

using Base.Test

@testset "State Times" begin 
  ## to do: statetime for invasive - death and no death scenarios. 
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
  ## This test set verifies protection levels are set correctly. It does two things:
  ## 1) It make sures protection() returns the right values for different combinations
  ## 2) It makes sure the plvl property of the human is assigned correctly by swap(), or app() functions.
  ## NOTE: Protection gained through vaccine is tested in the Vaccine test set. 
  
  ## <5, >5; natural immunity; no vaccine
  P = HiaParameters()
  M = ModelParameters()
  M.initializenew = true

  ## <5, >5; natural immunity; no vaccine; protection through swap()
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

  ## == 5; no vaccine; protection through app()
  h = setuphumans(1, P, M)[1];  
  h.age = 1824;
  app(h, P)
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
  ## This test set verifies vaccination scenarios are working correctly. 
  ## 1) It make sures protection() returns the right values for vaccine scenarios  
  ## 2) It checks if the protections levels are correctly set by vcc() 
  ## 3) It makes sure the vaccine expiry time is set correctly (2 - 5 years after primary)
  ## 3) It checks whether protection values are reset after vaccine expiry time is over
  ## 4) It makes sure primary/booster vaccine properties (pvaccine, bvaccine) are set properly
  ## 5) It verifies if numofdoses property error checking works.

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
  h.age = h.vaccineexpirytime   ## natural immunity after time of expiry
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
  h.age = h.vaccineexpirytime   ## natural immunity after time of expiry
  vcc(h, P)
  @test protection(h) == 0.5
  @test h.plvl == protection(h)
  
  h.age = P.dosethreetime
  vcc(h, P)  ## third dose given
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 3
  @test protection(h) == h.plvl
  @test h.vaccineexpirytime == tempvalue ## vaccine expiry time should not change as doses are given
  h.age = h.vaccineexpirytime   ## natural immunity after time of expiry
  vcc(h, P)
  @test protection(h) == 0.5
  @test h.plvl == protection(h)

  ## check error if doses given > 3..
  h.age = P.dosethreetime
  @test_throws ErrorException vcc(h, P)  


  ## its booster time, but booster is not given, check if protection and vaccine expiry time are correct
  h.age = P.boostertime
  P.boostercoverage = 0.0
  vcc(h, P) #booster time
  @test h.pvaccine == true 
  @test h.bvaccine == false
  @test h.dosesgiven == 3
  @test protection(h) == h.plvl
  @test h.vaccineexpirytime == tempvalue
  h.age = h.vaccineexpirytime   ## natural immunity after time of expiry
  vcc(h, P)
  @test protection(h) == 0.5
  @test h.plvl == protection(h)
  
  ## its booster time, force booster
  h.age = P.boostertime
  P.boostercoverage = 1.0  
  vcc(h, P) 
  @test h.pvaccine == true 
  @test h.bvaccine == true
  @test h.dosesgiven == 3
  @test h.plvl >= 0.85 && h.plvl <= 0.95
  @test h.vaccineexpirytime != tempvalue
  @test h.vaccineexpirytime >= (h.age + (6*365)) &&  h.vaccineexpirytime <= (h.age + (10*365))
  h.age = h.vaccineexpirytime  ## natural immunity after time of expiry
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
  ## This test set verifies after a human turns latent that his/her path is set correctly. 
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


@testset "Parameters" begin
  ## test if sequale enums end with MAJ or MIN (for the first 14 of them.. because we use this information in the costs calculation)  
  for i = 1:7
    @test string(INVSEQ(i))[(end - 2):end] == "MAJ"
  end
  for i = 8:14
    @test string(INVSEQ(i))[(end - 2):end] == "MIN"
  end
end



@testset "System" begin  
  ## This test set verifies humans are moving through comparments correctly.
  ## 1) It checks through tpp(), app() and as a consequence swap() functions are doing their job and setting the correct human properties.
  ## 2) It checks all movement between the model
  ##    -- LAT -> CAR -> REC -> SUSC
  ##    -- LAT -> SYM -> REC -> SUSC
  ##    -- LAT -> INV (nodeath) -> REC -> SUSC
  ##    -- LAT -> INV (dead) -> DEAD -> SUSC
  ##  note: transmission is not tested here, check Transmission testsets
  
  P = HiaParameters()
  M = ModelParameters()
  M.initializenew = true

  humans = setuphumans(1, P, M)
  ## see if a latent has been introduced
  @test length(find(x -> x.health == LAT, humans)) == 1

  ## test set: compartment movements by tpp() + swap() combos
  ## turning latent -> carriage -> recovered -> susceptible
  humans = setuphumans(1, P, M)
  h = humans[1]
  oldcnt = h.latcnt; 
  h.swap = LAT; swap(h, P); h.swap = UNDEF 
  ## check properties
  @test h.latcnt == oldcnt + 1;  @test h.path != 0;  @test h.plvl == 0
  ##force the path to 1 - so we can test probabilitlies
  h.path = 1
  h.timeinstate = h.statetime ## let the human expire  
  P.pathone_carriage_min = 1.0
  P.pathone_carriage_max::Float64 = 1.0
  P.pathone_symptomatic::Float64 = 0.0
  oldcnt = h.carcnt; 
  tpp(h, P)    ## should set the correct swap
  swap(h, P); h.swap = UNDEF 
  ## check common properties
  @test h.health == CAR; @test h.path == 0; @test h.plvl == 0; @test h.carcnt == oldcnt + 1
  ## recovery
  h.timeinstate = h.statetime; tpp(h, P); swap(h, P); h.swap = UNDEF 
  @test h.health == REC; @test h.path == 0; @test h.plvl != 0.0;
  ## susceptible
  h.timeinstate = h.statetime; tpp(h, P); swap(h, P); h.swap = UNDEF 
  @test h.health == SUSC; @test h.path == 0; @test h.plvl != 0.0;

  ## turning latent -> symptomatic
  humans = setuphumans(1, P, M)
  h = humans[1]
  oldcnt = h.symcnt
  h.swap = LAT; swap(h, P); h.swap = UNDEF                
  h.path = 1 ##force the path to 1 - so we can test probabilitlies
  h.timeinstate = h.statetime ## let the human expire  
  P.pathone_carriage_min = 0.0
  P.pathone_carriage_max::Float64 = 0.0
  P.pathone_symptomatic::Float64 = 1.0
  tpp(h, P)  
  swap(h, P); h.swap = UNDEF    
  @test h.health == SYMP; @test h.path == 0; @test h.plvl == 0; @test h.symcnt == oldcnt + 1
  ## recovery
  h.timeinstate = h.statetime; tpp(h, P); swap(h, P); h.swap = UNDEF 
  @test h.health == REC; @test h.path == 0; @test h.plvl != 0.0;
  ## susceptible
  h.timeinstate = h.statetime; tpp(h, P); swap(h, P); h.swap = UNDEF 
  @test h.health == SUSC; @test h.path == 0; @test h.plvl != 0.0;


  ## turning latent -> invasive (with invasive death on) -> DEAD
  humans = setuphumans(1, P, M)
  h = humans[1]
  oldcnt = h.invcnt
  h.swap = LAT; swap(h, P); h.swap = UNDEF                
  h.path = 1 ##force the path to 1 - so we can test probabilitlies
  h.timeinstate = h.statetime ## let the human expire  
  P.pathone_carriage_min = 0.0
  P.pathone_carriage_max::Float64 = 0.0
  P.pathone_symptomatic::Float64 = 0.0
  P.casefatalityratio = 1.0
  tpp(h, P)  
  swap(h, P); h.swap = UNDEF 
  ## check common properties
  @test h.health == INV; @test h.path == 0; @test h.plvl == 0; @test h.invcnt == oldcnt + 1
  ## check specific properties
  @test h.invdeath == true
  @test h.invtype == NOINV
  ## since invdeath is ON.. this should check if swap has been dead
  h.timeinstate = h.statetime; tpp(h, P); 
  @test h.swap == DEAD
  swap(h, P); h.swap = UNDEF 
  @test h.health == SUSC; ## swap function should reset to a "newborn"
  
  

  ## turning latent -> invasive (with invasive death off, force meningitis)
  humans = setuphumans(1, P, M)  ## get a fresh population
  h = humans[1]
  oldcnt = h.invcnt
  h.swap = LAT; swap(h, P); h.swap = UNDEF                
  h.path = 1 ##force the path to 1 - so we can test probabilitlies
  h.timeinstate = h.statetime ## let the human expire  
  P.pathone_carriage_min = 0.0
  P.pathone_carriage_max::Float64 = 0.0
  P.pathone_symptomatic::Float64 = 0.0
  P.casefatalityratio = 0.0
  ## force meningitis
  P.prob_invas_men = 1.0; P.prob_invas_pneu = 0.0; P.prob_invas_npnm = 0.0
  tpp(h, P)  
  swap(h, P); h.swap = UNDEF    ## cant run update - cost collection variable not setup in this test bench.
  ## check common properties
  @test h.health == INV; @test h.path == 0; @test h.plvl == 0; @test h.invcnt == oldcnt + 1
  ## check specific properties
  @test h.invdeath == false
  @test h.invtype != NOINV
  @test Int(h.invtype) >= 1 && Int(h.invtype) <= 15
  ## recovery
  h.timeinstate = h.statetime; tpp(h, P); swap(h, P); h.swap = UNDEF 
  @test h.health == REC; @test h.path == 0; @test h.plvl != 0;
  ## susceptible
  h.timeinstate = h.statetime; tpp(h, P); swap(h, P); h.swap = UNDEF 
  @test h.health == SUSC; @test h.path == 0; @test h.plvl != 0; 

  ## turning latent -> invasive (with invasive death off, force pneunomia)
  ##  note: we dont check recovery/susceptible here, no point... already checked above
  humans = setuphumans(1, P, M)  ## get a fresh population
  h = humans[1]
  oldcnt = h.invcnt
  h.swap = LAT; swap(h, P); h.swap = UNDEF                
  h.path = 1 ##force the path to 1 - so we can test probabilitlies
  h.timeinstate = h.statetime ## let the human expire  
  P.pathone_carriage_min = 0.0
  P.pathone_carriage_max::Float64 = 0.0
  P.pathone_symptomatic::Float64 = 0.0
  P.casefatalityratio = 0.0
  ## force meningitis
  P.prob_invas_men = 0.0; P.prob_invas_pneu = 1.0; P.prob_invas_npnm = 0.0
  tpp(h, P)  
  swap(h, P); h.swap = UNDEF    ## cant run update - cost collection variable not setup in this test bench.
  ## check common properties
  @test h.health == INV; @test h.path == 0; @test h.plvl == 0; @test h.invcnt == oldcnt + 1
  ## check specific properties
  @test h.invdeath == false
  @test h.invtype == PNEU

  ## turning latent -> invasive (with invasive death off, force NPNM)
  humans = setuphumans(1, P, M)  ## get a fresh population
  h = humans[1]
  oldcnt = h.invcnt
  h.swap = LAT; swap(h, P); h.swap = UNDEF                
  h.path = 1 ##force the path to 1 - so we can test probabilitlies
  h.timeinstate = h.statetime ## let the human expire  
  P.pathone_carriage_min = 0.0
  P.pathone_carriage_max::Float64 = 0.0
  P.pathone_symptomatic::Float64 = 0.0
  P.casefatalityratio = 0.0
  ## force meningitis
  P.prob_invas_men = 0.0; P.prob_invas_pneu = 0.0; P.prob_invas_npnm = 1.0
  tpp(h, P)  
  swap(h, P); h.swap = UNDEF    ## cant run update - cost collection variable not setup in this test bench.
  ## check common properties
  @test h.health == INV; @test h.path == 0; @test h.plvl == 0; @test h.invcnt == oldcnt + 1
  ## check specific properties
  @test h.invdeath == false
  @test h.invtype == NPNM


end


@testset "Transmission" begin
  P = HiaParameters()
  M = ModelParameters()
  M.initializenew = true
  humans = setuphumans(1, P, M)
  
  ## get a latent individual, make him symptomatic
  ld = find(x -> x.health == LAT, humans)[1]
  h = humans[ld]
  h.swap = SYMP; swap(h, P); h.swap = UNDEF 
  #dump(h)

  ## force an infection -- put to 2.0 because of protection levels
  P.betaone = 2.0    ## 0-2
  P.betatwo = 2.0    ##  2-5
  P.betathree = 2.0  ## 5-10, 60+
  P.betafour = 2.0   ## 10-60

  ## setup distributions for the dailycontact function
  n = filter(x -> x.age < 365, humans)
  f = filter(x -> x.age >= 365 && x.age < 1460, humans)
  s = filter(x -> x.age >= 1460 && x.age < 3285, humans)    
  t = filter(x -> x.age >= 3285, humans)

  mmt, cmt = distribution_contact_transitions()  ## get the contact transmission matrix. 
  ag1 = Categorical(mmt[1, :])
  ag2 = Categorical(mmt[2, :])
  ag3 = Categorical(mmt[3, :])
  ag4 = Categorical(mmt[4, :])

  ## run daily contact
  dailycontact(h, P, ag1, ag2, ag3, ag4, n, f, s, t)
  @test h.meetcnt == 1
  sickid = find(x -> x.swap == LAT, humans)
  @test length(sickid) == 1 ## only one person should've gotten sick
  @test humans[sickid[1]].sickfrom == h.agegroup_beta

end

# @testset "Costs" begin
#   P = HiaParameters()
#   M = ModelParameters()
#   M.initializenew = true
#   humans = setuphumans(1, P, M)
#   x = humans[1]
  
#   ## symptomatic cost, event happened first year
#   @test symptomatic_cost(x, P, 1)   
#   @test symptomatic_cost(x, P, 364)  
#   # symptomatic cost, event happened second year
#   @test symptomatic_cost(x, P, 365) 
#   @test symptomatic_cost(x, P, 729)  
  
#   # symptomatic cost, event happened 5th year
#   @test symptomatic_cost(x, P, 1460)
#   @test symptomatic_cost(x, P, 1824)

#   # test invasive 
#   @test invasive_good(x, P, 1) 
#   @test invasive_major(x, P, 1) 
#   @test invasive_minor(x, P, 1) 
#   println(collectcosts(x, P, 1))
# end
