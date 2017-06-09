## main system enums
@enum HEALTH SUSC LAT CAR PRE SYMP INV REC DEAD UNDEF
@enum GENDER MALE=1 FEMALE=2


## main system parameters
@with_kw immutable HiaParameters @deftype Int32
    # general parameters
    simtime = 365       ## time of simulation 40 years in days
    gridsize = 100000   ## size of population 
    inital_latent = 1   ## initial prevalence
    
    ## four betas, corresponding to jackson matrix age groups. 
    betaone::Float32 = 0.07
    betatwo::Float32 = 0.05
    betathree::Float32 = 0.05
    betafour::Float32 = 0.05
    
    
    latentshape::Float64 = 0.588
    latentscale::Float64 = 0.458
    latentmax = 4
    latentmin = 1   ##fix this by computing confidence intervals

    carriagemin = 14   ## days stayed in carriage, 2 weeks to 10 weeks
    carriagemax = 70   ## 10 weeks

    presympmin = 1     ## days stayed in presymptomatic

    symptomaticmean = 2 ## for poisson distribution
    symptomaticmin = 1 ## 1 day minimum symptomatic 
    symptomaticmax = 10 
    infaftertreatment = 2   ## after symptomatic, people get treatment -> adds 2 days of infectiousness. 

    recoveredmin = 2*365  ## two years for minimum time of staying recovered 
    recoveredmax = 5*365  ## max time of staying recovered.    

    invasivemin = 6
    invasivemax = 12

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
end

type DataCollection  ## data collection type.
    lat::Array{Int64}
    car::Array{Int64}
    sym::Array{Int64}
    inv::Array{Int64}
    rec::Array{Int64}
    DataCollection(size::Integer) = new(zeros(Int64, size), zeros(Int64, size), zeros(Int64, size),
                        zeros(Int64, size), zeros(Int64, size))
end


