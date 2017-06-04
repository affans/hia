## main system enums
@enum HEALTH SUSC LAT CAR PRE SYMP INV REC DEAD UNDEF
@enum GENDER MALE=1 FEMALE=2


## main system parameters
@with_kw immutable HiaParameters @deftype Int64
    # general parameters
    simtime = 30*360       ## time of simulation 40 years in days
    gridsize = 100000   ## size of population 
    inital_latent = 5   ## initial prevalence
    beta = 1
    
    latentshape::Float64 = 0.588
    latentscale::Float64 = 0.458
    latentmax = 4
    latentmin = 1   ##fix this by computing confidence intervals

    carriagemin = 14   ## days stayed in carriage, 2 weeks to 10 weeks
    carriagemax = 70   ## 10 weeks

    presympmin = 1     ## days stayed in presymptomatic

    symptomaticmin = 1 ## 1 day minimum symptomatic 
    symptomaticmax = 10 
    infaftertreatment = 2   ## after symptomatic, people get treatment -> adds 2 days of infectiousness. 

    recoveredmin = 2*365  ## two years for minimum time of staying recovered 
    recoveredmax = 5*365  ## max time of staying recovered.    

    pathone_carriage_min::Float64 = 0.04
    pathone_carriage_max::Float64 = 0.11
    pathone_symptomatic::Float64 = 0.90

    pathtwo_carriage_min::Float64 = 0.60
    pathtwo_carriage_max::Float64 = 0.90
    pathtwo_symptomatic::Float64 = 0.90
    
    paththree_carriage_min::Float64 = 0.90
    paththree_carriage_max::Float64 = 0.98
    paththree_symptomatic::Float64 = 0.98

    pathfour_carriage_min::Float64 = 0.90
    pathfour_carriage_max::Float64 = 0.98
    pathfour_symptomatic::Float64 = 1
    
    



end




