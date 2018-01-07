library(data.table)
library(ggplot2)
library(reshape2)
library(ggthemes)
library(plyr)
library(gridExtra)
library(grid)
library(RColorBrewer)
library(boot)

## disability weights
weights  = c(0.469, 0.099, 0.223, 0.388, 0.223, 0.359, 0.627)

## returns a log sequence, 1, 100, 1000, 10000 so on...
lseqBy <- function(from=1, to=1000000, by=1, length.out=log10(to/from)+1) {
  tmp <- exp(seq(log(from), log(to), length.out = length.out))
  tmp[seq(1, length(tmp), by)]  
}

## bootstrap mean
boot.mean <- function(dat, idx) mean(dat[idx], na.rm = TRUE)


## axis fonts and colors http://www.sthda.com/english/wiki/ggplot2-axis-ticks-a-guide-to-customize-tick-marks-and-labels

sdcc =  fread("./sep05/nolf/dcc_seed.dat", sep=",")
vdcc =  fread("./sep05/nolf/dcc_vaccine.dat", sep=",")
vdcc90 =  fread("./sep05/nolf/dcc_vaccine_90.dat", sep=",")
tdcc =  fread("./sep05/nolf/dcc_thirty.dat", sep=",")

vcsts = fread("./sep05/nolf/costs_vaccine.dat", sep=",")
vcsts90 = fread("./sep05/nolf/costs_vaccine_90.dat", sep=",")
tcsts = fread("./sep05/nolf/costs_thirty.dat", sep=",")

icsts = fread("./sep05/nolf/vac_vaccine.dat", sep=",")
icsts90 = fread("./sep05/nolf/vac_vaccine_90.dat", sep=",")
## add vaccine cost to this table
icsts[, price:=30]
icsts90[, price:=30]


################################
##  SINGLE COST CATEGORY      ##
################################
## plot costs, per year, averaged over sims
# get sum of daily costs over all simulations

## get daily costs, per simulation -- ie, add up all the sick humans on each day, each simulation
v = vcsts[order(systime), .(daysimtotal = sum(hosp)), by=.(systime, simid)] 
v = v[, year := ceiling(systime/365)] ## add the year column
## add up all the days at a yearly level, per simulation
v = v[, .(yearsimtotal = sum(daysimtotal)), by=.(year, simid)] ## add up the average costs per day for the year
## average out over 500 simulations, while running bootstrapping
v = v[, c("avg", "low", "high") := af(yearsimtotal, simid), by=.(year)]
## apply a yearly grouping 
v = v[, .(avg = max(avg), low=max(low), high=max(high)), by=.(year)]

## repeat the same for non-vaccine

## get daily costs, per simulation -- ie, add up all the sick humans on each day, each simulation
t = tcsts[order(systime), .(daysimtotal = sum(hosp)), by=.(systime, simid)] 
t = t[, year := ceiling(systime/365)] ## add the year column
## add up all the days at a yearly level, per simulation
t = t[, .(yearsimtotal = sum(daysimtotal)), by=.(year, simid)] ## add up the average costs per day for the year
## average out over 500 simulations, while running bootstrapping
t = t[, c("avg", "low", "high") := af(yearsimtotal, simid), by=.(year)]
## apply a yearly grouping 
t = t[, .(avg = max(avg), low=max(low), high=max(high)), by=.(year)]

#  v = vcsts[, .(total = sum(hosp)), by=.(systime)] 
#  v[, avg := total/500]      ## average sum over number of sims
#  v[, year := ceiling(systime/365)]    ## add year 
#  v = v[, .(avgtotal = sum(avg)), by=year] ## add up all the costs in one year

# t = tcsts[, .(total = sum(hosp)), by=.(systime)] 
# t[, avg := round(total/500, 0)]      ## average sum over number of sims
# t[, year := ceiling(systime/365)]    ## add year 
# t = t[, .(avgtotal = sum(avg)), by=year] ## add up all the costs in one year
# 
## plot the results
## contruct a data table merging both datasets
ff = data.table(year = as.factor(seq(1,10)), vac = v$avg, novac = t$avg) 
ff.m = melt(ff, id.vars="year")
gg = ggplot(ff.m)
gg = gg + geom_line(aes(year, value, group=variable, color=variable))
gg = gg + scale_color_discrete(labels = c(vac="Vaccine", novac="No Vaccine"))
gg = gg + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
#gg = gg + scale_fill_brewer(palette = "Accent")
gg


################################
##  COST TREND OVER YEARS     ##
################################
## With Vaccine Scenario Costs - trend without the vaccine adminstration costs
## average costs per day, summed over over the year

## get daily costs, per simulation -- ie, add up all the sick humans on each day, each simulation
v2 = tcsts[, .(p   = sum(phys),
               h   = sum(hosp), 
               m   = sum(med), 
               maj = sum(major), 
               min = sum(minor)), by=.(systime, simid)]
setkey(v2, systime) ## add a key
v2[, year := ceiling(systime/365)]    ## add year 
## add up all the days at a yearly level, per simulation
## so, ie for simulation 18.. add up at the yearly level for this simulation
v2 = v2[, .(p = sum(p), 
            h = sum(h), 
            m  = sum(m),
            maj  = sum(maj), 
            min  = sum(min)), by=.(year, simid)] ## add up all the costs in one year
## average out over 500 simulations, while running bootstrapping
## this also gives us 95% confidence intervals
v2 = v2[, c("pavg", "plow", "phigh") := af(p, simid), by=.(year)]
v2 = v2[, c("havg", "hlow", "hhigh") := af(h, simid), by=.(year)]
v2 = v2[, c("mavg", "mlow", "mhigh") := af(m, simid), by=.(year)]
v2 = v2[, c("majavg", "majlow", "majhigh") := af(maj, simid), by=.(year)]
v2 = v2[, c("minavg", "minlow", "minhigh") := af(min, simid), by=.(year)]
v2 = v2[, .(pavg = max(pavg), plow=max(plow), phigh=max(phigh), 
          havg = max(havg), hlow=max(hlow), hhigh=max(hhigh),
          mavg = max(mavg), mlow=max(mlow), mhigh=max(mhigh),
          majavg = max(majavg), majlow=max(majlow), majhigh=max(majhigh),
          minavg = max(minavg), minlow=max(minlow), minhigh=max(minhigh)), by=.(year)]

## sum up the data for ggplot (ie, get rid of the 95% conf intervals)
avgs = v2[, c("year", "pavg", "havg", "mavg", "majavg", "minavg")]
avgs.m = melt(avgs, id.vars = "year")

## create a table for lower bounds
lows = v2[, c("year","plow", "hlow", "mlow", "majlow", "minlow")]
lows.m = melt(lows, id.vars = "year")

## create a table for upper bounds
highs = v2[, c("year", "phigh", "hhigh", "mhigh", "majhigh", "minhigh")]
highs.m = melt(highs, id.vars = "year")

##plot the data
gg = ggplot(avgs.m)
gg = gg + geom_bar(aes(x=year, y=value, fill=variable, group=variable),width=0.7,stat="identity", position=position_dodge(width = 0.9))
gg = gg + geom_errorbar(aes(x=year, ymin=lows.m$value, ymax=highs.m$value, group=variable), width = 0.3, position = position_dodge(0.9)) 
#gg = gg + scale_fill_discrete(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"))
gg = gg + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
#gg = gg + labs(caption = "Daily average, aggregated over 10 years, vaccine administration cost not included")
#gg = gg + scale_colour_manual(values=c("#e41a1c","#377eb8","#4daf4a","#984ea3","#ff7f00"))
#gg = gg + scale_fill_brewer(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"), palette = "Paired")
gg = gg + scale_fill_manual("legend", values = c("pavg" = "#e41a1c", "havg" = "#377eb8", "mavg" = "#4daf4a", "majavg" = "#984ea3", "minavg" = "#ff7f00"))
gg = gg + scale_x_continuous(expand = c(0.01, 0), breaks=seq(1, 10, by=1), labels = seq(1, 10, by=1))
gg = gg + scale_y_continuous(expand = c(0.01, 0), limits = c(0, 1450000))
## the expand() makes it flush with the axis
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())
#gg = gg + theme(panel.grid.major = element_blank())
gg = gg + theme(axis.line = element_line(colour = "black"))
gg


## replace vcsts with tcsts/vcsts90
# v = vcsts[, .(p   = sum(phys)/500,
#               h   = sum(hosp)/500, 
#               m   = sum(med)/500, 
#               maj = sum(major)/500, 
#               min = sum(minor)/500), by=.(systime)]
# setkey(v, systime) ## add a key
# v[, year := ceiling(systime/365)]    ## add year 
# ## add up average costs per day over the year
# v = v[, .(p = sum(p), 
#           h = sum(h), 
#           m  = sum(m),
#           maj  = sum(maj), 
#           min  = sum(min)), by=year] ## add up all the costs in one year
# v.m = melt(v, id.vars = "year")
# 
# gg = ggplot(v.m)
# gg = gg + geom_bar(aes(year, value, fill=variable),width=0.7,stat="identity", position=position_dodge(width = 0.9))
# #gg = gg + scale_fill_discrete(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"))
# gg = gg + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
# #gg = gg + labs(caption = "Daily average, aggregated over 10 years, vaccine administration cost not included")
# #gg = gg + scale_colour_manual(values=c("#e41a1c","#377eb8","#4daf4a","#984ea3","#ff7f00"))
# #gg = gg + scale_fill_brewer(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"), palette = "Paired")
# gg = gg + scale_fill_manual("legend", values = c("p" = "#e41a1c", "h" = "#377eb8", "m" = "#4daf4a", "maj" = "#984ea3", "min" = "#ff7f00"))
# gg = gg + scale_x_continuous(expand = c(0.01, 0), breaks=seq(1, 10, by=1), labels = seq(1, 10, by=1))
# gg = gg + scale_y_continuous(expand = c(0.01, 0), limits = c(0, 1250000))
# ## the expand() makes it flush with the axis
# gg = gg + theme(legend.position="none")
# gg = gg + theme(panel.grid.minor = element_blank())
# #gg = gg + theme(panel.grid.major = element_blank())
# gg = gg + theme(axis.line = element_line(colour = "black"))
# gg
# 
# opts(
#   panel.grid.major = theme_line(size = 0.5, colour = '#1391FF'),
#   panel.grid.minor = theme_blank(),
#   panel.background = theme_blank(),
#   axis.ticks = theme_blank()
# )

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
gg = gg + geom_line(aes(year, value, group=variable, color=variable), size=1)
#gg = gg + scale_color_discrete(labels = c(="Vaccine", novac="No Vaccine"))
gg = gg + scale_color_manual("legend", values = c("directcosts" = "#984ea3", "totalcosts" = "#4daf4a", "novaccine" = "#e41a1c"))
gg = gg + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
#gg = gg + labs(caption = "Costs are averaged per day, over all simulations. The avg/day costs are added up at yearly level. \n Vaccine administration costs are not included")
#gg = gg + scale_fill_brewer(palette = "Accent")
## if using scale_colour_manual, need to supply "breaks" and color "values"
##  use scale_colour_manual if using custom colour pallete
gg = gg + scale_x_discrete(expand = c(0.01, 0), breaks=seq(1, 10, by=1), labels = seq(1, 10, by=1))
gg = gg + scale_y_continuous(expand = c(0.01, 0))
## the expand() makes it flush with the axis
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())
#gg = gg + theme(panel.grid.major = element_blank())
gg = gg + theme(axis.line = element_line(size = 0.9, colour = "black"))
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
c = vcsts[order(systime), .(direct = sum(phys, hosp, med, major, minor)), by=.(systime, simid)]
## add daily vaccine treatment costs, divide by 500 to get daily average
i = icsts[order(systime), .(treatment = sum(price)), by=.(systime, simid)]

c[, year := ceiling(systime/365)]    ## add year 
i[, year := ceiling(systime/365)]    ## add year 
## add up all the days at a yearly level, per simulation
## so, ie for simulation 18.. add up at the yearly level for this simulation
c = c[, .(direct = sum(direct)), by=.(year, simid)] ## add up all the costs in one year
i = i[, .(treatment = sum(treatment)), by=.(year, simid)] ## add up all the costs in one year

## add the direct costs to the treatment costs
ci = merge(x = i, y = c, by = c("year", "simid"), all = TRUE)
ci = NAToUnknown(ci, 0)
ci[, total := treatment + direct]
## get the averages by bootstrap method
ci[, c("avg", "lower", "upper") := af(total, simid), by=year]
ci = ci[, .(wv_avg = unique(avg), wv_lower=unique(lower), wv_upper=unique(upper)), by=year]

## get the no vaccine costs
t = tcsts[order(systime), .(novaccine = sum(phys, hosp, med, major, minor)), by=.(systime, simid)]
t[, year := ceiling(systime/365)]    ## add year 
## add up all the days at a yearly level, per simulation
## so, ie for simulation 18.. add up at the yearly level for this simulation
t = t[, .(novaccine = sum(novaccine)), by=.(year, simid)] ## add up all the costs in one year
t[, c("avg", "lower", "upper") := af(novaccine, simid), by=year]
t = t[, .(nv_avg = unique(avg), nv_lower=unique(lower), nv_upper=unique(upper)), by=year]

## set keys for merge
setkey(ci, year)
setkey(t, year)
d = merge(ci, t)

## create three melted datatables for ggplot
avgs = d[, c("year", "wv_avg", "nv_avg")]
avgs.m = melt(avgs, id.vars = "year")

## create a table for lower bounds
lows = d[, c("year","wv_lower", "nv_lower")]
lows.m = melt(lows, id.vars = "year")

## create a table for upper bounds
ups = d[, c("year", "wv_upper", "nv_upper")]
ups.m = melt(ups, id.vars = "year")

gg = ggplot(avgs.m)
gg = gg + geom_bar(aes(year, value, fill=variable), stat="identity", position="dodge", alpha=0.85)
gg = gg + geom_errorbar(aes(x=year, ymin=lows.m$value, ymax=ups.m$value, group=variable), width = 0.3, position = position_dodge(0.9)) 
gg = gg +  xlab("Time (in years)") + ylab("Total Cost") + theme_minimal()
gg = gg + scale_x_discrete(expand = c(0.01, 0), breaks=seq(1, 10, by=1), labels = seq(1, 10, by=1))
gg = gg + scale_y_continuous(expand = c(0.01, 0), limits = c(0, 3.3e6), breaks=seq(0, 3.5e6, by=0.5e6))
gg = gg + scale_fill_manual(values = c("#a6cee3", "#1f78b4"), labels = c(nt="No Vaccine Scenario", vt="Vaccine Scenario"))
## the expand() makes it flush with the axis
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())
#gg = gg + theme(panel.grid.major = element_blank())
gg = gg + theme(axis.line = element_line(colour = "black"))
gg
# 

# ## OLD CODE: WITHOUT BOOTSTRAP/ERROR BARS
# ## get direct hospital costs with vaccination scenario, divide by 500 to get daily average
# c = vcsts[, .(vaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
# ## add daily vaccine treatment costs, divide by 500 to get daily average
# i = icsts[, .(treatment = sum(price)/500), by=systime]
# ## get direct hospital costs, without vaccination scenario, divide by 500 to fget daily average
# t = tcsts[, .(novaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
# setkey(c, systime)
# setkey(i, systime)
# setkey(t, systime)
# tmp = merge(c, i)    ## merge the vaccine direct costs + vaccine treatment costs
# setkey(tmp, systime) ## attach a key to this new table
# ci = merge(tmp, t)   ## merge the novaccine costs
# ci[, withvaccine := Reduce(`+`, .SD), .SDcol = c(2, 3)]
# ci[, vaccine := NULL]
# ci[, treatment := NULL]
# setkey(ci, systime)
# 
# ## take the above data, total costs per day, and change to costs per year
# ci = ci[, year := ceiling(systime/365)] ## add the year column
# ci = ci[, .(nt=sum(novaccine), vt = sum(withvaccine)), by=year] ## sum up all the costs at the year level
# 
# ## create a side by side bar plot
# ## THIS IS THE SAME AS THE ABOVE "LINE PLOTS" BUT IN BAR GRAPH FORM
# ci.m = melt(ci, id.vars = "year")
# gg = ggplot(ci.m)
# gg = gg + geom_bar(aes(factor(year), value, fill=variable), stat="identity", position="dodge", alpha=0.85)
# gg = gg +  xlab("Time (in years)") + ylab("Total Cost") + theme_minimal()
# 
# gg = gg + scale_x_discrete(expand = c(0.01, 0), breaks=seq(1, 10, by=1), labels = seq(1, 10, by=1))
# gg = gg + scale_y_continuous(expand = c(0.01, 0), limits = c(0, 3e6), breaks=seq(0, 3e6, by=0.5e6))
# 
# gg = gg + scale_fill_manual(values = c("#a6cee3", "#1f78b4"), labels = c(nt="No Vaccine Scenario", vt="Vaccine Scenario"))
# 
# ## the expand() makes it flush with the axis
# gg = gg + theme(legend.position="none")
# gg = gg + theme(panel.grid.minor = element_blank())
# #gg = gg + theme(panel.grid.major = element_blank())
# gg = gg + theme(axis.line = element_line(colour = "black"))
# gg
# # 


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


#########################################
##  DALYS/CE PLANES and BOOTSTRAP      ##
#########################################
## CHECK THE c = vcsts[..] to make sure medivac is included or not
## get ALL costs with vaccination scenario, divide by 500 to get daily average
#c = vcsts90[, .(vaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
c = vcsts[, .(vaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
## add daily vaccine treatment costs, divide by 500 to get daily average
i = icsts[, .(treatment = sum(price)/500), by=systime]
## get direct hospital costs, without vaccination scenario, divide by 500 to fget daily average
#t = tcsts[, .(novaccine = sum(phys, hosp, med, major, minor)/500), by=systime]
t = tcsts[, .(novaccine = sum(phys, hosp,  med, major, minor)/500), by=systime]

setkey(c, systime)
setkey(i, systime)
setkey(t, systime)
tmp = merge(c, i)    ## merge the vaccine direct costs + vaccine treatment costs
setkey(tmp, systime) ## attach a key to this new table
ci = merge(tmp, t)   ## merge the novaccine costs
ci[, withvaccine := round(Reduce(`+`, .SD), 0), .SDcol = c(2, 3)]
ci$novaccine = round(ci$novaccine, 0)
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


## run bootstrap 
b = boot(ci, computeDailyICER, R = 5000)
bconf = boot.ci(b)

## ggplot variables 
## run the above separately, then add the two scenarios to the following variables
dtmedivac = DT
confmedivac = bconf

dtnomedivac = DT
confnomedivac = bconf

## plot the DT - the mean costs and mean DALYs
gg = ggplot()
gg = gg + geom_point(data = dtmedivac, aes(y = cost, x = as.numeric(daly)), color="#984ea3", alpha=0.40)
gg = gg + geom_segment(aes(x = 0, xend = 120, y = 0, yend = (confmedivac$normal[2])*120), color="#984ea3", linetype="twodash", size=1.25)
gg = gg + geom_segment(aes(x = 0, xend = 120, y = 0, yend = (confmedivac$normal[3])*120), color="#984ea3", linetype="twodash", size=1.25)
#gg = gg +  geom_abline(intercept = 0, slope=-50924, color="#984ea3", linetype="dashed")
#gg = gg +  geom_abline(intercept = 0, slope=-37441, color="#984ea3", linetype="dashed")

gg = gg + geom_point(data = dtnomedivac, aes(y = cost, x = as.numeric(daly)), color="#ff7f00", alpha=0.40)
gg = gg + geom_segment(aes(x = 0, xend = 120, y = 0, yend = (confnomedivac$normal[2])*120), color="#ff7f00", linetype="twodash", size=1.25)
gg = gg + geom_segment(aes(x = 0, xend = 120, y = 0, yend = (confnomedivac$normal[3])*120), color="#ff7f00", linetype="twodash", size=1.25)

#gg = gg +  geom_abline(intercept = 0, slope=-64526, color="#ff7f00", linetype="dashed")
#gg = gg +  geom_abline(intercept = 0, slope=-48728, color="#ff7f00", linetype="dashed")

#gg = gg + ggtitle("Cost-Effectiveness Plane") 
gg = gg + xlab("DALY Difference") + ylab("Cost Difference") + theme_minimal()

gg = gg + scale_x_continuous(limits = c(-10, 125), breaks=seq(-150, 150, by=10))
gg = gg + scale_y_continuous(limits = c(-8e6, 700000), breaks=seq(-9e6, 9e6, by=1e6))
gg = gg + geom_vline(xintercept=0)
gg = gg + geom_hline(yintercept=0)

gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())

gg


#####################################
##  ICER Sampling Distribution     ##
#####################################

gg = ggplot()
gg = gg + geom_histogram(aes(x=b$t), binwidth=5000, fill="#969696", col="white")
gg = gg + xlab("ICER") + ylab("count") + theme_minimal()
gg = gg + scale_x_continuous(expand = c(0.01, 0), breaks=seq(-60000, -30000, by=5000))
gg = gg + scale_y_continuous(expand = c(0.01, 0), limits= c(0, 300))
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())
#gg = gg + theme(panel.grid.major = element_blank())
gg = gg + theme(axis.line = element_line(colour = "black"))
gg

