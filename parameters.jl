## main system enums

@enum HEALTH SUSC=1 LAT=2 CAR=3 SYMP=4 INV=5 REC=6 DEAD=7 UNDEF=8
@enum GENDER MALE=1 FEMALE=2
@enum INVSEQ COGMAJ=1 SEIZMAJ=2 HEARLOSSMAJ=3 MOTORMAJ=4 VISUALMAJ=5 IMPAIRMAJ=6 MIMPAIRMAJ=7 COGMIN=8 SEIZMIN=9 HEARLOSSMIN=10 MOTORMIN=11 VISUALMIN=12 IMPAIRMIN=13 MIMPAIRMIN=14 MENNOSEQ=15 PNEU=16 NPNM=17 NOINV=18
## NOTE: Enum integer values set up this way because the categorical distribution distribution_sequlae(). Ie, if invasive is meningitis, pick a random number from this categorical distribution yeilds a number from 1 - 15 .. which I then call INVSEQ(integer_value) to convert to the Enum.. if the invasive is pneu, npnm then we just set it manually. 


## main system parameters
@with_kw type ModelParameters 
    initializenew::Bool = true      ## are we initializing a new population or reading old JLD serialized data.
    numofsims::Int64 = 50           ## how much sims to run
    numofprocessors::Int64 = 50     ## number of processors to use    
    savejld::Bool = true            ## whether we should save files at the end of simulation. 
    readloc::String  = "./aug31/serial/"    #serialfolder in the form of "{dir}/"
    writeloc::String = "./serial/"   #serialfolder in the form of "{dir}/"
    vaccineon::Bool = true
end

## simulation parameters
@with_kw type HiaParameters @deftype Int64
    # general parameters
    simtime = 365         ## time of simulation 40 years in days
    gridsize = 100000      ## size of population 
    inital_latent = 1     ## initial prevalence    
    vaccinetime = 0       ## years (in days) added on top of simtime
    
    ## four betas, corresponding to CDC (U shaped incidence data) age groups. 
    # betaone::Float64 = 0.0723    ## 0-2
    # betatwo::Float64 = 0.0527    ##  2-5
    # betathree::Float64 = 0.0426  ## 5-10, 60+
    # betafour::Float64 = 0.0699   ## 10-60

    betaone::Float64 = 0.0793    ## 0-2
    betatwo::Float64 = 0.0545    ##  2-5
    betathree::Float64 = 0.0491  ## 5-10, 60+
    betafour::Float64 = 0.0799   ## 10-60
    
    carriagereduction::Float64 = 0.5
    
    avgallsexlife = 71     ## average lifetime for both sex
    avgmalelife = 68*365   ## average lifetime for male
    avgfemalelife = 74*365 ## average lifetime for female.

    discount_cost::Float64 = 0.03
    discount_benefit::Float64 = 0.03
    
    
    ## if invasive, probability of going to meningitis (major, minor, non-disability meningititis , pneumonia, npnm)
    ## data from the american arctic paper - might need some refinement - paper has data based on children/adult. 

    prob_invas_men::Float64 = 0.33
    prob_invas_pneu::Float64  = 0.29
    prob_invas_npnm::Float64  = 0.38

    prob_invas_maj_seq_cog::Float64       = 0.01
    prob_invas_maj_seq_seiz::Float64      = 0.015
    prob_invas_maj_seq_hearloss::Float64  = 0.032
    prob_invas_maj_seq_motor::Float64     = 0.012
    prob_invas_maj_seq_visual::Float64    = 0.001
    prob_invas_maj_seq_impair::Float64    = 0.007
    prob_invas_maj_seq_mimpair::Float64   = 0.019

    prob_invas_min_seq_cog::Float64       = 0.024
    prob_invas_min_seq_seiz::Float64      = 0.0    ## no data given for this
    prob_invas_min_seq_hearloss::Float64  = 0.006
    prob_invas_min_seq_motor::Float64     = 0.013
    prob_invas_min_seq_visual::Float64    = 0.001
    prob_invas_min_seq_impair::Float64    = 0.008
    prob_invas_min_seq_mimpair::Float64   = 0.006

   

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

    ## how long they will stay in hospital if invasive AND not marked for death
    hospitalmin_nodeath = 8    ## if no death is marked for invasive, 
    hospitalmax_nodeath = 12   ##  length 8 - 12 days

    ## how long they will stay in hospital if invasive AND are marked for death
    hospitalmin_death = 1      
    hospitalmax_death = 10     ## length of hospital stay = Poisson(4)
    hospitalmean_death = 4     ## with min/max 1/10 - chosen so that 25% of 

    #death due to disease. 
    casefatalityratio::Float64 = 0.091 ## case fatality ratios

    ## lifetime reduction 
    lfreducemajormin = 2 ##
    lfreducemajormax = 10    
    lfreduceminormin = 2
    lfreduceminormax = 2

    ## path one
    pathone_carriage_min::Float64 = 0.04
    pathone_carriage_max::Float64 = 0.11
    pathone_symptomatic::Float64 = 0.90

    ## path two
    pathtwo_carriage_min::Float64 = 0.60
    pathtwo_carriage_max::Float64 = 0.90
    pathtwo_symptomatic::Float64 = 0.60 
    
    ## path three
    paththree_carriage_min::Float64 = 0.90
    paththree_carriage_max::Float64 = 0.98
    paththree_symptomatic::Float64 = 0.90

    ## path four
    pathfour_carriage_min::Float64 = 0.90
    pathfour_carriage_max::Float64 = 0.98
    pathfour_symptomatic::Float64 = 0.93

    ## path five
    pathfive_carriage_min::Float64 = 0.90
    pathfive_carriage_max::Float64 = 0.98
    pathfive_symptomatic::Float64 = 0.97

    ## path six
    pathsix_carriage_min::Float64 = 0.90
    pathsix_carriage_max::Float64 = 0.98
    pathsix_symptomatic::Float64 = 1.0

    ## path seven
    pathseven_carriage_min::Float64 = 0.60
    pathseven_carriage_max::Float64 = 0.90
    pathseven_symptomatic::Float64 = 0.95

    ## vaccine parameters
    primarycoverage::Float64 = 0.77  ## source: https://www.canada.ca/en/public-health/services/publications/healthy-living/vaccine-coverage-canadian-children-highlights-2013-childhood-national-immunization-coverage-survey.html
    boostercoverage::Float64 = 0.935 ## 72/77 # source: http://healthycanadians.gc.ca/publications/healthy-living-vie-saine/immunization-coverage-children-2013-couverture-vaccinale-enfants/alt/icc-2013-cve-eng.pdf
    primarytimemin = 2*365 ## 2 years
    primarytimemax = 5*365 
    boostertimemin = 6*365
    boostertimemax = 10*365
    doseonetime    = 60   ## 2 months - 60 days, 
    dosetwotime    = 120  ## 4 months
    dosethreetime  = 180  ## 6 months
    boostertime    = 450  ## booster given at 15 months.      

    ## costs 
    ##  -- these are per night 
    cost_physicianvisit     = 60
    cost_antibiotics        = 0
    cost_medivac            = 55000
    cost_averagehospital    = 11548  ## average cost of hospital, used if invdeath = true
    
    cost_meningitis_major   = 109664 ## per year major seq cost
    
    ## to do: convert these to today's value. these are from rob's paper
    cost_minor_infant       = 27914 ## 14000  ## 0 - 2
    cost_minor_preschool    = 21434 ## 85737 total.. per year from 2 - 6  
    cost_minor_school       = 26917 ## this is per year until 18 years of age
    cost_minor_adult        = 13957  ## from 18-22 

    cost_vaccine_dose       = 20
    cost_administration     = 8
    cost_wastage            = 0 ## 3 - 5% -- added on top of the vaccine coverage, only affects cost
    
end


