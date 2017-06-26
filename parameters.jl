## main system enums
@enum HEALTH SUSC LAT CAR SYMP INV REC DEAD UNDEF
@enum GENDER MALE=1 FEMALE=2
@enum INVTYPE NOINV=0 MEN=1 PNM=2 NPNM=3 

## main system parameters
@with_kw immutable HiaParameters @deftype Int32
    # general parameters
    simtime = 365         ## time of simulation 40 years in days
    gridsize = 100000     ## size of population 
    inital_latent = 1     ## initial prevalence    
    vaccinetime = 0       ## years (in days) added on top of simtime
    
    ## four betas, corresponding to CDC (U shaped incidence data) age groups. 
    betaone::Float32 = 0.05    ## 0-2
    betatwo::Float32 = 0.04    ##  2-5
    betathree::Float32 = 0.03  ## 5-10, 60+
    betafour::Float32 = 0.02   ## 10-60
    carriagereduction::Float32 = 0.5
    
    invmeningitis::Float32 = 0.33
    invpneumonia::Float32 = 0.29
    invother::Float32 = 0.38
    
    latentshape::Float64 = 0.588
    latentscale::Float64 = 0.458
    latentmax = 4
    latentmin = 1   ##fix this by computing confidence intervals

    carriagemin = 14   ## days stayed in carriage, 2 weeks to 10 weeks
    carriagemax = 70   ## 10 weeks

    symptomaticmean = 2 ## for poisson distribution
    symptomaticmin = 1 ## 1 day minimum symptomatic 
    symptomaticmax = 10 

    infaftertreatment = 2   ## after symptomatic, people get treatment -> adds 2 days of infectiousness. 

    recoveredmin = 2*365  ## two years for minimum time of staying recovered 
    recoveredmax = 5*365  ## max time of staying recovered.    

    invasive_nohospital = 10 ## fixed 10 days .. duration of treatment. s
        
    hospitalmin_nodeath = 8    ## if no death is marked for invasive, 
    hospitalmax_nodeath = 12   ##  length 8 - 12 days

    
    hospitalmin_death = 1      ## if marked for death, 
    hospitalmax_death = 10     ## length of hospital stay = Poisson(4)
    hospitalmean_death = 4     ## with min/max 1/10 - chosen so that 25% of 


    casefatalityratio::Float64 = 0.091 ## case fatality ratios

    ## path one
    pathone_carriage_min::Float64 = 0.04
    pathone_carriage_max::Float64 = 0.11
    pathone_symptomatic::Float64 = 0.90

    ## path two
    pathtwo_carriage_min::Float64 = 0.60
    pathtwo_carriage_max::Float64 = 0.90
    pathtwo_symptomatic::Float64 = 0.95
    
    ## path three
    paththree_carriage_min::Float64 = 0.90
    paththree_carriage_max::Float64 = 0.98
    paththree_symptomatic::Float64 = 0.98

    ## path four
    pathfour_carriage_min::Float64 = 0.90
    pathfour_carriage_max::Float64 = 0.98
    pathfour_symptomatic::Float64 = 1.0

    ## primary dosage at 2, 4, 6 months
    doseonetime    = 60   ## 2 months - 60 days, 
    dosetwotime    = 120  ## 4 months
    dosethreetime  = 180  ## 6 months
    boostertime    = 450  ## booster given at 15 months.      

    ## costs 
    treatmentcost = 0
    hospitalcost  = 0
    disability_minorcost = 0 
    disability_majorcost = 0
    productivitycost = 0
    meningitiscost = 0
    pneumoniacost = 0
    npnmcost = 0

end
