## cost analysis version 2.0

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

## averaging and bootstrapping function to compute error bars
af <- function(cost, sims){
  ## setup a vector corressponding to 500 simulations
  vec = rep(0, 500)
  ## replace the 0's in the new vector by sims that have positive/good data
  vec[sims] = cost
  ## vec is now a vector of 500 sims
  # for reproduceablility 
  set.seed(912)
  b = boot(vec, boot.mean, R=1000)
  c = boot.ci(b)
  rm(.Random.seed, envir=globalenv()) ## remove the set seed
  return(list(r1 = b$t0, r2 = c$normal[2], r3 =c$normal[3]))
}

## data load
## incidence for the first 30 years
sdcc =  fread("./sep05/nolf/dcc_seed.dat", sep=",")
##incidence with vaccine @ 77% coverage
vdcc =  fread("./sep05/nolf/dcc_vaccine.dat", sep=",")
##incidence with vaccine @ 90% coverage
vdcc90 =  fread("./sep05/nolf/dcc_vaccine_90.dat", sep=",")
##incidence with no vaccine
tdcc =  fread("./sep05/nolf/dcc_thirty.dat", sep=",")

## total costs with 77% coverage
vcsts = fread("./sep05/nolf/costs_vaccine.dat", sep=",")
## total costs with 90% coverage
vcsts90 = fread("./sep05/nolf/costs_vaccine_90.dat", sep=",")
## total costs without vaccine
tcsts = fread("./sep05/nolf/costs_thirty.dat", sep=",")

## costs of vaccination program at 77% coverage
icsts = fread("./sep05/nolf/vac_vaccine.dat", sep=",")
## costs of vaccination program at 90% coverage
icsts90 = fread("./sep05/nolf/vac_vaccine_90.dat", sep=",")
## add vaccine cost to this table
icsts[, price:=30]
icsts90[, price:=30]


################################
##  SINGLE COST CATEGORY      ##
################################
## replace vcsts with tcsts/vcsts90 for other scenarios

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

#####################################
##  COST CATEGORIES OVER YEARS     ##
#####################################
## With/Without Vaccine Scenario Costs - does not include vaccine administration
#####################################
## get daily costs, per simulation -- ie, add up all the sick humans on each day, each simulation
rm(datset)
#datset = vcsts
#datset = vcsts90
datset = tcsts

## sum up all the costs of each category per day, per simulation
v2 = datset[, .(p   = sum(phys),
               h   = sum(hosp), 
               m   = sum(med), 
               maj = sum(major), 
               min = sum(minor)), by=.(systime, simid)]
setkey(v2, systime) ## add a key
## add year 
v2[, year := ceiling(systime/365)] 

## add up all the days at a yearly level, per simulation
## so, ie for simulation 18.. add up at the yearly level for this simulation
v2 = v2[, .(p = sum(p), 
            h = sum(h), 
            m  = sum(m),
            maj  = sum(maj), 
            min  = sum(min)), by=.(year, simid)] ## add up all the costs in one year


## average out over 500 simulations, while running bootstrapping
## this also gives us 95% confidence intervals, lower and upper limit
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
#c("#e41a1c", "#377eb8", "#377eb8", "#377eb8", "#377eb8")
gg = gg + geom_bar(aes(x=year, y=value, fill=variable, group=variable),width=0.7,stat="identity", position=position_dodge(width = 0.9))
gg = gg + geom_errorbar(aes(x=year, ymin=lows.m$value, ymax=highs.m$value, group=variable), color=rep(c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3", "#ff7f00"), 10), width = 0.3, position = position_dodge(0.9)) 
#gg = gg + scale_fill_discrete(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"))
gg = gg + xlab("Time (in years)") + ylab("Costs") + theme_minimal()
#gg = gg + labs(caption = "Daily average, aggregated over 10 years, vaccine administration cost not included")
#gg = gg + scale_colour_manual(values=c("#e41a1c","#377eb8","#4daf4a","#984ea3","#ff7f00"))
#gg = gg + scale_fill_brewer(labels = c(p="Physician", h="Hospital", m="Medivac", maj="Major", min="Minor"), palette = "Paired")
# original colors
#gg = gg + scale_fill_manual("legend", values = c("pavg" = "#e41a1c", "havg" = "#377eb8", "mavg" = "#4daf4a", "majavg" = "#984ea3", "minavg" = "#ff7f00"))
gg = gg + scale_fill_manual("legend", values = c("pavg" = "#FFB870", "havg" = "#C291CA", "mavg" = "#8ECF8C", "majavg" = "#81B2D9", "minavg" = "#F17E80"))

gg = gg + scale_x_continuous(expand = c(0.01, 0), breaks=seq(1, 10, by=1), labels = seq(1, 10, by=1))
gg = gg + scale_y_continuous(expand = c(0.01, 0), limits = c(0, 1.8e6), breaks=seq(0, 1.8e6, by=0.2e6), labels=seq(0, 1.8e6, by=0.2e6)/1000000)
## the expand() makes it flush with the axis
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())
#gg = gg + theme(panel.grid.major = element_blank())
gg = gg + theme(axis.line = element_line(colour = "black"))


gg = gg + theme(axis.title=element_blank())
#gg = gg + theme(axis.text=element_blank())
gg = gg + theme(axis.text=element_text(size=24))
gg


#############################################
##  TOTAL COST COMPARISON PER YEAR (BAR PLOTS)  ##
#############################################
## This includes vaccine administration costs
#############################################
rm(datset_total)
rm(datset_vaccine)
datset_total = vcsts
datset_vaccine = icsts

## get all direct hospital costs with vaccination scenario, at a per day/per simulation level
c = datset_total[order(systime), .(direct = sum(phys, hosp, med, major, minor)), by=.(systime, simid)]
## add daily vaccine treatment costs, divide by 500 to get daily average, per day/per simulation level
i = datset_vaccine[order(systime), .(treatment = sum(price)), by=.(systime, simid)]

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
## same the tenth year data for percent reductions
ndb = rep(0, 500)  #for 500 sims
## load up ndb in the right simulation index
ndb[t[year == 10]$simid] = t[year==10]$novaccine

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
gg = gg + geom_errorbar(aes(x=year, ymin=lows.m$value, ymax=ups.m$value, group=variable), color=rep(c("#f82912", "#3979a7"), 10), width = 0.2, position = position_dodge(0.9)) 
gg = gg +  xlab("Time (in years)") + ylab("Total Cost") + theme_minimal()
gg = gg + scale_x_continuous(expand = c(0.01, 0), breaks=seq(1, 10, by=1), labels = seq(1, 10, by=1))
gg = gg + scale_y_continuous(expand = c(0.01, 0), limits = c(0, 3.5e6), breaks=seq(0, 3.5e6, by=0.5e6), labels=seq(0, 3.5e6, by=0.5e6)/1000000)
#gg = gg + scale_fill_manual(values = c("#739dd3", "#fdc086"), labels = c(nt="No Vaccine Scenario", vt="Vaccine Scenario"))
gg = gg + scale_fill_manual(values = c("#80b1d3", "#fb8072"), labels = c(nt="No Vaccine Scenario", vt="Vaccine Scenario"))

## the expand() makes it flush with the axis
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())
#gg = gg + theme(panel.grid.major = element_blank())
gg = gg + theme(axis.line = element_line(colour = "black"))

gg = gg + theme(axis.title=element_blank())
#gg = gg + theme(axis.text=element_blank())
gg = gg + theme(axis.text=element_text(size=24))

gg

## save the tenth year data for percent reductions
vdb = rep(0, 500)  #for 500 sims
## load up vdb in the right simulation index
vdb[ci[year == 10]$simid] = ci[year==10]$total



# 
## calculate percent reduction by using boot again 
## set the seed to be the same so the results will be the same
set.seed(912)
vmeans = boot(vdb, boot.mean, R = 1000)
nmeans = boot(ndb, boot.mean, R = 1000)


## check means are equal to the data above. 
## ie, check the tenth year in ci and t for the means
## and run boot.ci(vmeans) and boot.ci(nmeans) and check ci, t table to check for lower/upper limits

## mean reduction
(mean(nmeans$t0) - mean(vmeans$t0))/mean(nmeans$t0)

## calculate range
v = sample(vmeans$t)  ## pick a random 1000 
n = sample(nmeans$t)
# 
mean(v)
# [1] 862261.6
mean(n)
# [1] 1860083

## do pairwise reduction 
r = (n - v)/n
mean(r)
# [1] 0.522979

r = rep(0, 5000)

for (i in seq(1, 5000)){
  vidx = sample(1:1000, 1)
  nidx = sample(1:1000, 1)
  r[i] = (nmeans$t[nidx]-vmeans$t[vidx])/nmeans$t[nidx]
}

# get conf intervals from library(Rmisc)
## it should be noted that this data isnt really normal
## check with hist(r), kinda skewed
## use willcox to test and get confidence intervals
wilcox.test(r, conf.int = T)
rm(.Random.seed, envir=globalenv()) ## remove the set seed

## with the seed set above (and the two samples()) used
## the result should always be
# 95 percent confidence interval:
#   0.5235827 0.5370069

#########################################
##  DALYS/CE PLANES and BOOTSTRAP      ##
#########################################
## use temporary var for for different scenarios
rm(vdcc_tmp)
rm(vcst_tmp)
rm(icst_tmp)
vdcc_tmp = vdcc90
vcst_tmp = vcsts90
icst_tmp = icsts90
## SCENARIO: REMOVE OR ADD MEDIVAC COSTS AND ASSIGN THE CORRECT VARIABLE BELOW
## get ALL costs with vaccination scenario, divide by 500 to get daily average
c = vcst_tmp[, .(vaccine = sum(phys, hosp, major, minor)/500), by=systime]
## add daily vaccine treatment costs, divide by 500 to get daily average
i = icst_tmp[, .(treatment = sum(price)/500), by=systime]
## get direct hospital costs, without vaccination scenario, divide by 500 to fget daily average
t = tcsts[, .(novaccine = sum(phys, hosp, major, minor)/500), by=systime]

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

## at this point we have our daily costs, we need to calculate daily dalys
## we need to calculate daily DALYS

## figure out who died from invasive disease, calculate their yld and yll, yld = 0 in this case
A = vdcc_tmp[invdeath == "true"]
A[, L := (expectancy - age)/365 ]       # get remaining life in years
A[, yllind := (1/0.03)*(1 - exp(-0.03*L))] # discount the years by 3%
A = A[, .(YLLdaily = sum(yllind)/500), by=systime] 
A[, YLDdaily:=0] ## they have no disability cuz all these people died
A[, dalyA := YLLdaily + YLDdaily]
setkey(A, systime)

## get all people who got disability, calculate their yld and yll
B = vdcc_tmp[health == 5 & invtype %in% seq(1, 7)]
B[, w := weights[invtype]]
B[, L := (expectancy - age)/365 ]
B[, Ldis := L - expectancyreduced]
B[, Ldead := expectancyreduced]
B[, yldind := w*(1/0.03)*(1 - exp(-0.03*Ldis))]
B[, yllind := exp(-0.03*Ldis)*(1/0.03)*(1 - exp(-0.03*Ldead))]
B = B[, .(YLDdaily = sum(yldind)/500, YLLdaily=sum(yllind)/500), by=systime] 
B[, dalyB := YLLdaily + YLDdaily]
setkey(B, systime)


#merge(A[, c("systime", "dalyA")], B, all = T)


## do the same for non-vaccine scenario
C = tdcc[invdeath == "true"]
C[, L := (expectancy - age)/365 ]       # get remaining life in years
C[, yllind := (1/0.03)*(1 - exp(-0.03*L))] # discount the years by 3%
C = C[, .(YLLdaily = sum(yllind)/500), by=systime] 
C[, YLDdaily:=0] ## they have no disability cuz all these people died
C[, dalyC := YLLdaily + YLDdaily]
setkey(C, systime)

## get all people who got disability
D = tdcc[health == 5 & invtype %in% seq(1, 7)]
D[, w := weights[invtype]]
D[, L := (expectancy - age)/365 ]
D[, Ldis := L - expectancyreduced]
D[, Ldead := expectancyreduced]
D[, yldind := w*(1/0.03)*(1 - exp(-0.03*Ldis))]
D[, yllind := exp(-0.03*Ldis)*(1/0.03)*(1 - exp(-0.03*Ldead))]
D = D[, .(YLDdaily = sum(yldind)/500, YLLdaily=sum(yllind)/500), by=systime] 
D[, dalyD := YLLdaily + YLDdaily]
setkey(D, systime)

ci = merge(ci, A[, c("systime", "dalyA")], all.x = T)
ci = merge(ci, B[, c("systime", "dalyB")], all.x = T)
ci = merge(ci, C[, c("systime", "dalyC")], all.x = T)
ci = merge(ci, D[, c("systime", "dalyD")], all.x = T)
ci = NAToUnknown(ci, 0)
## add the death dalys  and the disability dalys together to get total dalys per day
ci[, "vaccinedaly" := dalyA + dalyB]
ci[, "novaccinedaly" := dalyC + dalyD]
## remove unneccasry columns
ci[, c("dalyA", "dalyB", "dalyC", "dalyD") := NULL]


icerbootstrap <- function(dat, idx){
  mvc = sum(dat[idx, withvaccine])
  mnc = sum(dat[idx, novaccine])
  mvd = sum(dat[idx, vaccinedaly])
  mnd = sum(dat[idx, novaccinedaly])
  costdiff = mvc-mnc
  dalydiff = -(mvd-mnd)
  return(c(costdiff/dalydiff, costdiff, dalydiff))
}

## run bootstrap 
## the bootstrap object b has three columns. column 1 is ICER, 2 is cost, 3 is daly (so 1 = 2/3)
set.seed(912)
b = boot(ci, icerbootstrap, R = 3651)
## get confidence interval for the ICER
b.conf = boot.ci(b, index=1) ## index = 1 is the ICER, index=2 is the cost diff, index=3 is the DALY diff
rm(.Random.seed, envir=globalenv()) ## remove the set seed

dtmedivac = data.table(cost = b$t[, 2], daly = b$t[, 3]) ## create a data table out of cost and daly from the bootstrap 
confmedivac = b.conf

dtnomedivac = data.table(cost = b$t[, 2], daly = b$t[, 3]) ## create a data table out of cost and daly from the bootstrap 
confnomedivac = b.conf


## plot the DT - the mean costs and mean DALYs
gg = ggplot()
gg = gg + geom_point(data = dtmedivac, aes(y = cost, x = as.numeric(daly)), color="#984ea3", alpha=0.40)
## if changing the xend, make sure to change the yend (consider y=mx+b, b = 0 in this case)
gg = gg + geom_segment(aes(x = 0, xend = 130, y = 0, yend = (confmedivac$normal[2])*130), color="#984ea3", linetype="twodash", size=1.25)
gg = gg + geom_segment(aes(x = 0, xend = 130, y = 0, yend = (confmedivac$normal[3])*130), color="#984ea3", linetype="twodash", size=1.25)
#gg = gg +  geom_abline(intercept = 0, slope=-50924, color="#984ea3", linetype="dashed")
#gg = gg +  geom_abline(intercept = 0, slope=-37441, color="#984ea3", linetype="dashed")
gg = gg + geom_point(data = dtnomedivac, aes(y = cost, x = as.numeric(daly)), color="#ff7f00", alpha=0.40)
gg = gg + geom_segment(aes(x = 0, xend = 130, y = 0, yend = (confnomedivac$normal[2])*130), color="#ff7f00", linetype="twodash", size=1.25)
gg = gg + geom_segment(aes(x = 0, xend = 130, y = 0, yend = (confnomedivac$normal[3])*130), color="#ff7f00", linetype="twodash", size=1.25)
#gg = gg +  geom_abline(intercept = 0, slope=-64526, color="#ff7f00", linetype="dashed")
#gg = gg +  geom_abline(intercept = 0, slope=-48728, color="#ff7f00", linetype="dashed")
#gg = gg + ggtitle("Cost-Effectiveness Plane") 
gg = gg + xlab("DALY Difference") + ylab("Cost Difference") + theme_minimal()
gg = gg + scale_x_continuous(limits = c(-10, 135), breaks=seq(-150, 150, by=10))
gg = gg + scale_y_continuous(limits = c(-8e6, 700000), breaks=seq(-9e6, 9e6, by=1e6), labels=seq(-9e6, 9e6, by=1e6)/1000000)
gg = gg + geom_vline(xintercept=0)
gg = gg + geom_hline(yintercept=0)
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())

gg


#####################################
##  ICER Sampling Distribution     ##
#####################################
## the bootstrap object b has three columns. column 1 is ICER, 2 is cost, 3 is daly (so 1 = 2/3)
gg = ggplot()
gg = gg + geom_histogram(aes(x=b$t[, 1]), binwidth=500, fill="#969696", col="white")
gg = gg + xlab("ICER") + ylab("count") + theme_minimal()
gg = gg + scale_x_continuous(expand = c(0.01, 0), breaks=seq(-60000, -30000, by=5000))
gg = gg + scale_y_continuous(expand = c(0.01, 0), limits= c(0, 300))
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())
#gg = gg + theme(panel.grid.major = element_blank())
gg = gg + theme(axis.line = element_line(colour = "black"))
gg



