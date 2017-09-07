library(data.table)
library(ggplot2)
library(reshape2)
library(ggthemes)
library(plyr)
library(gridExtra)
library(grid)
library(RColorBrewer)
library(boot)


weights  = c(0.469, 0.099, 0.223, 0.388, 0.223, 0.359, 0.627)

## creates a log sequence, 1, 100, 1000, 10000 so on...
lseqBy <- function(from=1, to=1000000, by=1, length.out=log10(to/from)+1) {
  tmp <- exp(seq(log(from), log(to), length.out = length.out))
  tmp[seq(1, length(tmp), by)]  
}


sdcc =  fread("./sep05/nolf/dcc_seed.dat", sep=",")
vdcc =  fread("./sep05/nolf/dcc_vaccine.dat", sep=",")
tdcc =  fread("./sep05/nolf/dcc_thirty.dat", sep=",")

vcsts = fread("./sep05/nolf/costs_vaccine.dat", sep=",")
tcsts = fread("./sep05/nolf/costs_thirty.dat", sep=",")
icsts = fread("./sep05/nolf/vac_vaccine.dat", sep=",")

## add vaccine cost to this table
icsts[, price:=30]


################################
##  SINGLE COST CATEGORY  ##
################################
## plot costs, per year, averaged over sims
# get sum of daily costs over all simulations
v = vcsts[, .(total = sum(hosp)), by=.(systime)] 
v[, avg := round(total/500, 0)]      ## average sum over number of sims
v[, year := ceiling(systime/365)]    ## add year 
v = v[, .(avgtotal = sum(avg)), by=year] ## add up all the costs in one year

## repeat the same for non-vaccine
t = tcsts[, .(total = sum(hosp)), by=.(systime)] 
t[, avg := round(total/500, 0)]      ## average sum over number of sims
t[, year := ceiling(systime/365)]    ## add year 
t = t[, .(avgtotal = sum(avg)), by=year] ## add up all the costs in one year

## plot the results
## contruct a data table merging both datasets
ff = data.table(year = as.factor(seq(1,10)), vac = v$avgtotal, novac = t$avgtotal) 
ff.m = melt(ff, id.vars="year")
gg = ggplot(ff.m)
gg = gg + geom_line(aes(year, value, group=variable, color=variable))
gg = gg + scale_color_discrete(labels = c(vac="Vaccine", novac="No Vaccine"))
gg = gg + ggtitle("Physician Costs/Year") + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
gg = gg + labs(caption = "Costs are averaged per day, over all simulations. The avg/day costs are added up at yearly level")
#gg = gg + scale_fill_brewer(palette = "Accent")
gg


################################
##  COST TREND OVER YEARS     ##
################################
## With Vaccine Scenario Costs - trend without the vaccine adminstration costs
## average costs per day
v = vcsts[, .(p   = sum(phys)/500,
              h   = sum(hosp)/500, 
              m   = sum(med)/500, 
              maj = sum(major)/500, 
              min = sum(minor)/500), by=.(systime)]
setkey(v, systime) ## add a key
v[, year := ceiling(systime/365)]    ## add year 
## add up average costs per day over the year
v = v[, .(p = sum(p), 
          h = sum(h), 
          m  = sum(m),
          maj  = sum(maj), 
          min  = sum(min)), by=year] ## add up all the costs in one year
v.m = melt(v, id.vars = "year")
gg = ggplot(v.m)
gg = gg + geom_bar(aes(year, value, fill=variable), stat="identity", position="dodge")
#gg = gg + scale_fill_discrete(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"))
gg = gg + ggtitle("Cost distribution over 10 years, with vaccine program") + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
gg = gg + labs(caption = "Daily average, aggregated over 10 years, vaccine administration cost not included")
gg = gg + scale_fill_brewer(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"), palette = "Paired")
gg

## No-Vaccine scenario cost trend, repeat the same as above
v = tcsts[, .(p   = sum(phys)/500,
              h   = sum(hosp)/500, 
              m   = sum(med)/500, 
              maj = sum(major)/500, 
              min = sum(minor)/500), by=.(systime)]
setkey(v, systime)
v[, year := ceiling(systime/365)]    ## add year 
v = v[, .(p = sum(p), 
          h = sum(h), 
          m  = sum(m),
          maj  = sum(maj), 
          min  = sum(min)), by=year] ## add up all the costs in one year
v.m = melt(v, id.vars = "year")
gg = ggplot(v.m)
gg = gg + geom_bar(aes(year, value, fill=variable), stat="identity", position="dodge")
#gg = gg + scale_fill_discrete(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"))
gg = gg + ggtitle("Cost distribution over 10 years, without vaccine program") + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
gg = gg + labs(caption = "Daily average, aggregated over 10 years")
gg = gg + scale_fill_brewer(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"), palette = "Paired")
gg


#############################################
##  TOTAL COST TREND PER YEAR (LINE PLOTS) ##
#############################################
## how this works, well we calculate incidence every day. 
## ie, on day i, the average incidence was something
## so in that sense, we need the "costs" associated with that incidence
## Differnece between this and above is that the above separates the cost categories


## get the total costs from the main data table 
c = vcsts[, .(total = sum(phys, hosp, med, minor, major)), by=systime]
c = c[, avg:=total/500] ## average it per day over 500 sims
c = c[, year := ceiling(systime/365)] ## add the year column
c = c[, .(avgtotal = round(sum(avg), 0)), by=year] ## add up the average costs per day for the year

## repeat the above steps for no vaccine scenario
t = tcsts[, .(total = sum(phys, hosp, med, minor, major)), by=systime]
t = t[, avg:=total/500] ## average it per day over 500 sims
t = t[, year := ceiling(systime/365)] ## add the year column
t = t[, .(avgtotal = round(sum(avg), 0)), by=year] ## add up the average costs per day for the year

## repeat the above steps for treatment
i = icsts[, .(total = sum(price)), by=systime]
i = i[, avg:=total/500] ## average it per day over 500 sims
i = i[, year := ceiling(systime/365)] ## add the year column
i = i[, .(avgtotal = round(sum(avg), 0)), by=year] ## add up the average costs per day for the year

## alternative would be to add the averages at the day level for vaccine admin costs and direct costs
## -> we do this below when we do the bar plots

## contruct a data table merging both datasets
ff = data.table(year = as.factor(seq(1,10)), directcosts = c$avgtotal, totalcosts = (c$avgtotal + i$avgtotal), novaccine = t$avgtotal) 
ff.m = melt(ff, id.vars="year")
gg = ggplot(ff.m)
gg = gg + geom_line(aes(year, value, group=variable, color=variable))
gg = gg + scale_color_discrete(labels = c(vac="Vaccine", novac="No Vaccine"))
gg = gg + ggtitle("Costs per year, with vaccine administration") + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
gg = gg + labs(caption = "Costs are averaged per day, over all simulations. The avg/day costs are added up at yearly level. \n Vaccine administration costs are not included")
#gg = gg + scale_fill_brewer(palette = "Accent")
## if using scale_colour_manual, need to supply "breaks" and color "values"
##  use scale_colour_manual if using custom colour pallete
gg


#############################################
##  TOTAL COST TREND PER YEAR (BAR PLOTS)  ##
#############################################
## this is the same as above - except we do bar plots
## also, there is a slight calculation difference. 
## above, we calcualte daily average, aggregate over year for direct costs 
## we do the same for the vaccine admin costs.. then we add them together at a yearly level
## below, we add both costs (direct, vaccine) at the daily level, then aggregate to year
## numbers should be the same, however rounding errors may creep up..

## get direct hospital costs with vaccination scenario, divide by 500 to get daily average
c = vcsts[, .(vaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
## add daily vaccine treatment costs, divide by 500 to get daily average
i = icsts[, .(treatment = sum(price)/500), by=systime]
## get direct hospital costs, without vaccination scenario, divide by 500 to fget daily average
t = tcsts[, .(novaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
setkey(c, systime)
setkey(i, systime)
setkey(t, systime)
tmp = merge(c, i)    ## merge the vaccine direct costs + vaccine treatment costs
setkey(tmp, systime) ## attach a key to this new table
ci = merge(tmp, t)   ## merge the novaccine costs
ci[, withvaccine := round(Reduce(`+`, .SD), 0), .SDcol = c(2, 3)]
ci[, vaccine := NULL]
ci[, treatment := NULL]
setkey(ci, systime)

## take the above data, total costs per day, and change to costs per year
ci = ci[, year := ceiling(systime/365)] ## add the year column
ci = ci[, .(vt = sum(withvaccine), nt=sum(novaccine)), by=year] ## sum up all the costs at the year level

## create a side by side bar plot
## THIS IS THE SAME AS THE ABOVE "LINE PLOTS" BUT IN BAR GRAPH FORM
ci.m = melt(ci, id.vars = "year")
gg = ggplot(ci.m)
gg = gg + geom_bar(aes(factor(year), value, fill=variable), stat="identity", position="dodge")
gg = gg + scale_fill_discrete(labels = c(vt="Vaccine Scenario", nt="No Vaccine Scenario"))
gg = gg + ggtitle("Costs Per Year") + xlab("Time (in years)") + ylab("Total Cost") + theme_minimal()
gg = gg + labs(caption = "Costs are averaged per day, over 500 simulations. The avg/day costs are aggregated at yearly level.")
gg = gg + scale_y_continuous(limits = c(0, 3e6), breaks=seq(0, 3e6, by=0.5e6))
gg


######################################
##  RAW TREATMENT COST/SIMULATION   ##
######################################
## can be used to check stability in the system

i = icsts[, .(tot = sum(price)), by=.(simid)]
gg = ggplot(i)
gg = gg + geom_line(aes(simid, tot))
gg = gg + ggtitle("Cost of vaccine treatment, per simulation") + xlab("Simulation Number") + ylab("Costs") + theme_minimal()
gg = gg + labs(caption = "Seems that vaccine costs over all simulations are pretty stable")
gg


###################################
##  CE PLANES and BOOTSTRAP      ##
###################################
## get direct hospital costs with vaccination scenario, divide by 500 to get daily average
c = vcsts[, .(vaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
## add daily vaccine treatment costs, divide by 500 to get daily average
i = icsts[, .(treatment = sum(price)/500), by=systime]
## get direct hospital costs, without vaccination scenario, divide by 500 to fget daily average
t = tcsts[, .(novaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
setkey(c, systime)
setkey(i, systime)
setkey(t, systime)
tmp = merge(c, i)    ## merge the vaccine direct costs + vaccine treatment costs
setkey(tmp, systime) ## attach a key to this new table
ci = merge(tmp, t)   ## merge the novaccine costs
ci[, withvaccine := round(Reduce(`+`, .SD), 0), .SDcol = c(2, 3)]
ci[, vaccine := NULL]
ci[, treatment := NULL]
setkey(ci, systime)

## we need to calculate daily DALYS
yll_v = vdcc[invdeath == "true"]
yll_v[, L := (expectancy - age)/365 ]       # get remaining life in years
yll_v[, YLL := (1/0.03)*(1 - exp(-0.03*L))] # discount the years by 3%
yll_v = yll_v[, .(yllv = sum(YLL)/500), by=systime] 
setkey(yll_v, systime)

yld_v = vdcc[health == 5 & invtype %in% seq(1, 7)]
yld_v[, w := weights[invtype]]
yld_v[, L := (expectancy - age)/365 ]
yld_v[, YLD := w*(1/0.03)*(1 - exp(-0.03*L))]
yld_v = yld_v[, .(yldv = sum(YLD)/500), by=systime] 
setkey(yld_v, systime)

yll_t = tdcc[invdeath == "true"]
yll_t[, L := (expectancy - age)/365 ] # discount the years by 3%
yll_t[, YLL := (1/0.03)*(1 - exp(-0.03*L))]
yll_t = yll_t[, .(yllt = sum(YLL)/500), by=systime] 
setkey(yll_t, systime)

yld_t = tdcc[health == 5 & invtype %in% seq(1, 7)]
yld_t[, w := weights[invtype]]
yld_t[, L := (expectancy - age)/365 ]
yld_t[, YLD := w*(1/0.03)*(1 - exp(-0.03*L))]
yld_t = yld_t[, .(yldt = sum(YLD)/500), by=systime] 
setkey(yld_t, systime)

ci = merge(ci, yll_v, all.x = T)
ci = merge(ci, yld_v, all.x = T)
ci = merge(ci, yll_t, all.x = T)
ci = merge(ci, yld_t, all.x = T)

ci[is.na(ci$yllv), "yllv"]= 0
ci[is.na(ci$yldv), "yldv"]= 0
ci[is.na(ci$yllt), "yllt"]= 0
ci[is.na(ci$yldt), "yldt"]= 0

ci[, dalyvaccine := Reduce(`+`, .SD), .SDcol = c(4, 5)]
ci[, dalynovaccine := Reduce(`+`, .SD), .SDcol = c(6, 7)]

## for bootstrap, create data table to hold values
DT <<- data.table(
  cost = integer(),
  daly = character()
)

## for bootstrap, calculate daily icer
computeDailyICER <- function(x, i){
  #print(x)
  mvc = sum(x[i, withvaccine])
  mnc = sum(x[i, novaccine])
  mvd = sum(x[i, dalyvaccine])
  mnd = sum(x[i, dalynovaccine])
  costdiff = mvc-mnc
  dalydiff = -(mvd-mnd)
  DT <<- rbind(DT, list(costdiff, dalydiff))
  return(costdiff/dalydiff)
}

## define a threshold value
Rc = 150000

## run bootstrap 
b = boot(ci, computeDailyICER, R = 5000)

## plot the DT - the mean costs and mean DALYs
gg = ggplot()
gg = gg + geom_point(data = DT, aes(y = cost, x = as.numeric(daly)), color="blue", alpha=0.50)
gg = gg + scale_x_continuous(limits = c(0, 130), breaks=seq(-150, 150, by=10))
gg = gg + scale_y_continuous(limits = c(-6e6, 0), breaks=seq(-9e6, 9e6, by=1e6))
gg = gg + ggtitle("Cost-Effectiveness Plane") 
gg = gg + xlab("DALY Difference") + ylab("Cost Difference") + theme_minimal()
gg = gg + geom_vline(xintercept=0)
gg = gg + geom_hline(yintercept=0)
gg

################################
##  Confidence Interval       ##
################################
## make sure bootstrap object b exists
boot.ci(b)

#####################################
##  ICER Sampling Distribution     ##
#####################################
gg = ggplot()
gg = gg + geom_histogram(aes(x=b$t), binwidth=500)
gg = gg + ggtitle("ICER Sampling Distribution of Nonparametric Bootstrap")
gg = gg + ggtitle("Raw values, nonparametric bootstrap") 
gg = gg + xlab("Bootstrap sample") + ylab("ICER") + theme_minimal()
gg = gg + labs(caption = "5000 bootstrap replicates")
gg


## YLL/YLD CALCULATION, raw numbers 
# --- essentially useless 

## all death due to invasive
##   -- check whether invdeath == true && health != 5 is zero
##   -- you cant have invasive death and be non-invasive health
yll_v = vdcc[invdeath == "true"]
yll_v[, year := ceiling(systime/365)]
yll_v[, L := (expectancy - age)/365 ]       # get remaining life in years
yll_v[, YLL := (1/0.03)*(1 - exp(-0.03*L))] # discount the years by 3%
yll_v = yll_v[, .(yll = sum(YLL)), by=year] 

yll_t = tdcc[invdeath == "true"]
yll_t[, year := ceiling(systime/365)]
yll_t[, L := (expectancy - age)/365 ] # discount the years by 3%
yll_t[, YLL := (1/0.03)*(1 - exp(-0.03*L))]
yll_t = yll_t[, .(yll = sum(YLL)), by=year] 


## every sim should only have one unique ID.
## unless someone dies in that sim, is reborn, and gets invasive again


#calculate YLD for those that are major disabled.
weights  = c(0.469, 0.099, 0.223, 0.388, 0.223, 0.359, 0.627)
yld_v = vdcc[health == 5 & invtype %in% seq(1, 7)]
yld_v[, year := ceiling(systime/365)]
yld_v[, w := weights[invtype]]
yld_v[, L := (expectancy - age)/365 ]
yld_v[, YLD := w*(1/0.03)*(1 - exp(-0.03*L))]
yld_v = yld_v[, .(yld = sum(YLD)), by=year] 

yld_t = tdcc[health == 5 & invtype %in% seq(1, 7)]
yld_t[, year := ceiling(systime/365)]
yld_t[, w := weights[invtype]]
yld_t[, L := (expectancy - age)/365 ]
yld_t[, YLD := w*(1/0.03)*(1 - exp(-0.03*L))]
yld_t = yld_t[, .(yld = sum(YLD)), by=year] 

ff = data.table(year = as.factor(seq(1, 10)), yld = yld_v$yld, yll = yll_v$yll,
                yld = yld_t$yld, yll = yll_t$yll)

ff.m = melt(ff, id.vars = "year")
ff.m[, treatment:=rep(c("vaccine", "no vaccine"), each=20)]

gg = ggplot(ff.m)
gg = gg + geom_bar(aes(x = year, value, fill=variable), position="stack", stat="identity")
gg = gg + scale_fill_discrete(labels = c(yll="YLL", yld="YLD"))
gg = gg + facet_wrap( ~ treatment)
gg = gg + ggtitle("DALYs, all scenarios") + xlab("Time (in years)") + ylab("Value") + theme_minimal()


## DEPRECATED CODE
###### COST PER YEAR , WITHOUT TREATMENT, NO SIM AVERAGE, RAW NUMBERS
## this is not really good data.. we need to average them.

## COSTS per time unit
c = vcsts[, year := ceiling(systime/365)]
c = vcsts[, .(phys = sum(phys), hosp=sum(hosp), med=sum(med), major=sum(major), minor=sum(minor)), by=year]
c = vcsts[, .(total = sum(phys, hosp, med, minor, major)), by=year]

t = tcsts[, year := ceiling(systime/365)]
t = tcsts[, .(phys = sum(phys), hosp=sum(hosp), med=sum(med), major=sum(major), minor=sum(minor)), by=year]
t = tcsts[, .(total = sum(phys, hosp, med, minor, major)), by=year]


## contruct a data table merging both datasets
ff = data.table(year = as.factor(seq(1,10)), vt = c$total, tt = t$total) 
ff.m = melt(ff, id.vars="year")
gg = ggplot(ff.m)
gg = gg + geom_bar(aes(factor(year), value, fill=variable), stat="identity", position="dodge")
gg = gg + scale_fill_discrete(labels = c(vt="Vaccine", tt="No Vaccine"))
gg = gg + ggtitle("Costs per year: novaccine/with vaccine") + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
gg = gg + labs(caption = "ATTN: Raw cost - no averaging")
#gg = gg + scale_fill_brewer(palette = "Accent")
## if using scale_colour_manual, need to supply "breaks" and color "values"
##  use scale_colour_manual if using custom colour pallete






