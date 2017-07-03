## main system enums
@enum HEALTH SUSC LAT CAR SYMP INV REC DEAD UNDEF
@enum GENDER MALE=1 FEMALE=2
@enum INVTYPE NOINV=0 MENNOD=1 MENMAJ=2 MENMIN=3 PNM=4 NPNM=5

## main system parameters
@with_kw type ModelParameters 
    numofsims::Int32 = 50
    #numofprocessors::Int32 = 50
    verbose::Bool = false
    savejld::Bool = true
    read_serialdatalocation::String = "./serial/"    #serialfolder in the form of "{dir}/"
    write_serialdatalocation::String = "./serial/"   #serialfolder in the form of "{dir}/"
    vaccineon::Bool = true
end

## simulation parameters
@with_kw immutable HiaParameters @deftype Int32
    # general parameters
    simtime = 365         ## time of simulation 40 years in days
    gridsize = 100000     ## size of population 
    inital_latent = 1     ## initial prevalence    
    vaccinetime = 0       ## years (in days) added on top of simtime
    
    ## four betas, corresponding to CDC (U shaped incidence data) age groups. 
    betaone::Float32 = 0.0722    ## 0-2
    betatwo::Float32 = 0.0526    ##  2-5
    betathree::Float32 = 0.0426  ## 5-10, 60+
    betafour::Float32 = 0.0699   ## 10-60
    carriagereduction::Float32 = 0.5
    
    ## if invasive, probability of going to meningitis (major, minor, non-disability meningititis , pneumonia, npnm)
    ## data from the american arctic paper - might need some refinement - paper has data based on children/adult. 

    #invmeningitis::Float32 = 0.33
    ## when setting up the categorical distribution, meningitis major, minor, none must add up to 33%. The probabilities given below are scaled. In other words, for major meningitis disability its 9.5 out of a 100 people, which means 3.135 out of 33 people.  See Excel file for clarification.
    prob_invas_men_major::Float32 = 0.03135 ### non-scaled 0.095 (7.1 - 15.2) interval 
    prob_invas_men_minor::Float32 = 0.01881 ### non-scaled 0.057
    prob_invas_men_nodis::Float32 = 0.27984 ### nonscaled 1 - (0.095 + 0.057) = 0.848
    prob_invas_pneu::Float32 = 0.29
    prob_invas_npnm::Float32 = 0.38

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
        
    
    ## how long they will stay in hospital if invasive AND not marked for death
    hospitalmin_nodeath = 8    ## if no death is marked for invasive, 
    hospitalmax_nodeath = 12   ##  length 8 - 12 days

    ## how long they will stay in hospital if invasive AND are marked for death
    hospitalmin_death = 1      
    hospitalmax_death = 10     ## length of hospital stay = Poisson(4)
    hospitalmean_death = 4     ## with min/max 1/10 - chosen so that 25% of 

    #death due to disease. 
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
    basictreatmentcost = 0  
    basichospitalcost  = 0
    meningitismajorcost = 0
    meningitisminorcost = 0
    pneumoniacost = 0
    npnmcost = 0

end

