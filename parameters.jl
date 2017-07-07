## main system enums
@enum HEALTH SUSC LAT CAR SYMP INV REC DEAD UNDEF
@enum GENDER MALE=1 FEMALE=2
@enum INVSEQ COGMAJ=1 SEIZMAJ=2 HEARLOSSMAJ=3 MOTORMAJ=4 VISUALMAJ=5 IMPAIRMAJ=6 MIMPAIRMAJ=7 COGMIN=8 SEIZMIN=9 HEARLOSSMIN=10 MOTORMIN=11 VISUALMIN=12 IMPAIRMIN=13 MIMPAIRMIN=14 NOSEQ=15 PNEU=16 NPNM=17
## NOTE: Enum integer values set up this way because the categorical distribution distribution_sequlae(). Ie, if invasive is meningitis, pick a random number from this categorical distribution yeilds a number from 1 - 15 .. which I then call INVSEQ(integer_value) to convert to the Enum.. if the invasive is pneu, npnm then we just set it manually. 


## main system parameters
@with_kw type ModelParameters 
    initializenew::Bool = true      ## are we initializing a new population or reading old JLD serialized data.
    numofsims::Int32 = 50           ## how much sims to run
    numofprocessors::Int32 = 50     ## number of processors to use    
    savejld::Bool = true            ## whether we should save files at the end of simulation. 
    readloc::String  = "./serial/"    #serialfolder in the form of "{dir}/"
    writeloc::String = "./serial/"   #serialfolder in the form of "{dir}/"
    vaccineon::Bool = true
end

## simulation parameters
@with_kw type HiaParameters @deftype Int32
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

    prob_invas_men::Float32 = 0.33
    prob_invas_pneu::Float32  = 0.29
    prob_invas_npnm::Float32  = 0.38

    prob_invas_maj_seq_cog::Float32       = 0.01
    prob_invas_maj_seq_seiz::Float32      = 0.015
    prob_invas_maj_seq_hearloss::Float32  = 0.032
    prob_invas_maj_seq_motor::Float32     = 0.012
    prob_invas_maj_seq_visual::Float32    = 0.001
    prob_invas_maj_seq_impair::Float32    = 0.007
    prob_invas_maj_seq_mimpair::Float32   = 0.019

    prob_invas_min_seq_cog::Float32       = 0.024
    prob_invas_min_seq_seiz::Float32      = 0.0    ## no data given for this
    prob_invas_min_seq_hearloss::Float32  = 0.006
    prob_invas_min_seq_motor::Float32     = 0.013
    prob_invas_min_seq_visual::Float32    = 0.001
    prob_invas_min_seq_impair::Float32    = 0.008
    prob_invas_min_seq_mimpair::Float32   = 0.006



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
    meningitismajorcost = 0
    meningitisminorcost = 0
    pneumoniacost = 0
    npnmcost = 0

end

