library(data.table)
library(ggplot2)
library(reshape2)
library(ggthemes)
library(plyr)
library(gridExtra)
library(grid)
library(RColorBrewer)

## TO DO: IMPLEMENT VARIABLES FOR NUMOFSIMS, NUMOFDAYS

#readLines("dcc.dat", n = 2)
dcc = fread("dcc.dat", sep=",")
csts = fread("costs.dat", sep=",")

## hs == 5  implies invasive.. see parameters.jl file for ENUM values.
hs = 5
ff = dcc[health==hs, .(cnt = length(ID), avg = length(ID)/500, year = ceiling(systime/365)),  by=.(systime, agegroup)]
ff = ff[order(year), .(yearsum = sum(avg)), by = .(year, agegroup)]

## remember to change this for VACCINE/NOVACCINE SCENARIO
ff[,  maf:= round(mean(yearsum[10:30]), 3), by=agegroup]



## all agegroups on a single plot

legendvals = sort(ff[, paste("Ag", agegroup, ": ", max(maf), sep=""), by=agegroup]$V1)

gg = ggplot(ff)
gg = gg + geom_line(aes(year, yearsum, group=factor(agegroup), colour=factor(agegroup)))
gg = gg + geom_line(aes(year, maf, group=factor(agegroup), colour=factor(agegroup)), linetype='dashed')
gg = gg + scale_colour_hue(labels = legendvals)
gg = gg + labs(color='Mean after 10') + ggtitle("Yearly Invasive") + xlab("Time (in years)") + ylab("Incidence") + theme_minimal()
gg
## if using scale_colour_manual, need to supply "breaks" and color "values"
##  use scale_colour_manual if using custom colour pallete

## one particular agegroup
#gg = ggplot(subset(ff, agegroup == 1)) 
#gg = gg + geom_line(aes(year, yearsum, group=factor(agegroup), colour=factor(agegroup)))

### WAIFU matrix
w = dcc[health == 2, .(cnt = length(ID)), by=.(agegroup, sickfrom)]
w[, csum := sum(cnt), by=agegroup]
w[, cavg := cnt/csum]
# in order:  w[order(agegroup, sickfrom)]
gg = ggplot(data = w, aes(y = factor(agegroup), x = factor(sickfrom))) 
gg = gg +   geom_tile(aes(fill = cavg)) + scale_fill_gradient(low = "white",high = "steelblue")+ geom_text(aes(label = round(cavg, 3))) 
gg = gg + labs(fill='%val') + ggtitle("Force of Infection/WAIFW") + xlab("From...") + ylab("Agegroup getting sick") + theme_minimal()
gg = gg + scale_x_discrete(position = "top") 
gg

##costs per simulation
c = csts[major > 0]
## this is a check that in any one simulation, how many times a particular ID is sick
## should be one, as they cant be invasive twice. 
csts[, length(ID), by=.(ID, simid)]

## plot symptomatic costs, per simulation
ss = csts[, .(total = sum(phys)), by=.(simid)]
gg = ggplot(ss) 
gg = gg + geom_point(aes(simid, total))
gg = gg + scale_y_log10(breaks=lseqBy())
gg = gg + ggtitle("Costs (Symptomatic)") + xlab("simulation ID") + ylab("cost") + theme_minimal()
overmil = nrow(ss[total > 1e6])
zeros = nrow(ss[total == 0])
gg = gg + labs(caption = paste("zero sims:", zeros))
gg

ss = csts[, .(total = sum(hosp)), by=.(simid)]
gg = ggplot(ss) 
gg = gg + geom_point(aes(simid, total))
gg = gg + scale_y_log10(breaks=lseqBy(to=1e10))
gg = gg + ggtitle("Costs (Hospital)") + xlab("simulation ID") + ylab("cost") + theme_minimal()
zeros = nrow(ss[total == 0])
gg = gg + labs(caption = paste("zero sims:", zeros))
gg


ss = csts[, .(total = sum(med)), by=.(simid)]
gg = ggplot(ss) 
gg = gg + geom_point(aes(simid, total))
#gg = gg + scale_y_log10(breaks=lseqBy(to=1e10))
gg = gg + ggtitle("Costs (Medivac)") + xlab("simulation ID") + ylab("cost") + theme_minimal()
zeros = nrow(ss[total == 0])
gg = gg + labs(caption = paste("zero sims:", zeros))
gg

ss = csts[, .(total = sum(minor)), by=.(simid)]
gg = ggplot(ss) 
gg = gg + geom_point(aes(simid, total))
#gg = gg + scale_y_log10(breaks=lseqBy(to=1e10))
gg = gg + ggtitle("Costs (Minor)") + xlab("simulation ID") + ylab("cost") + theme_minimal()
zeros = nrow(ss[total == 0])
gg = gg + labs(caption = paste("zero sims:", zeros))
gg



## creates a log sequence, 1, 100, 1000, 10000 so on...
lseqBy <- function(from=1, to=1000000, by=1, length.out=log10(to/from)+1) {
  tmp <- exp(seq(log(from), log(to), length.out = length.out))
  tmp[seq(1, length(tmp), by)]  
}


##costs per time unit
c = csts
c = c[, year := ceiling(systime/365)]
c = c[, .(phys = sum(phys), hosp=sum(hosp), med=sum(med), major=sum(major), minor=sum(minor)), by=year]

## melt the data - long format
c.m = melt(c, id.vars ="year")
gg = ggplot(c.m)
gg = gg + geom_bar(aes(factor(year), value, fill=variable), stat="identity", position="dodge")
gg = gg + scale_y_log10(breaks=lseqBy(to=1e9))
gg = gg + scale_fill_brewer(palette = "Accent")

## all death due to invasive
dcc[invdeath == "true"]

## check which are health 5 but not 7.. this happens because they turn health 5
## when the simulation ends, and dont have time to move to dead
## because of this, we will use health == 5 to capture all invasive deaths
a = dcc[invdeath == "true" & health == 5]$ID
b = dcc[invdeath == "true" & health == 7]$ID
a[which(!(a %in% b))]
dcc[invdeath == "true" & ID %in% a[which(!(a %in% b))]]

a = dcc[invdeath == "true" & health == 5]
b = csts

## dont need to do this after...
setnames(b, "time", "systime")

mm = merge(a, b, by=c("ID", "health", "simid", "systime"))
which(is.na(mm$ID) == TRUE)
dcc[invdeath == "true", .(cnt=length(health)), by=ID]$cnt

c = csts[, .(cnt = length(time)), by = .(ID, simid, health)]
c[cnt > 1 & health == 5, ]
csts[ID == 5 & simid==266]
dcc[ID == 5 & simid == 266]

dcc[health == 1]

mm[, L := (expectancy - age)/365, ]
mm[, YLL := (1/0.03)*(1 - exp(-0.03*L))]

## total DALYs by sim
mmy = mm[, .(sumyll = sum(YLL)), by=simid]
df = data.table(simid = seq(1:500), sumyll = 0)
setkey(mmy, simid)
setkey(df, simid)

mm.m = merge(df, mmy, all.x = TRUE)
mm.m = mm.m[, .(s = sumyll.x + sumyll.y), by=simid]

gg = ggplot(mm.m)
gg = gg + geom_bar(aes(simid, s), stat="identity" )
zeros = nrow(mm.m[is.na(s)])
gg = gg + labs(caption = paste("zero sims:", zeros))
gg = gg + ggtitle("Number of YLLs/sim level") + xlab("simulation number") + ylab("YLL count") + theme_minimal()





