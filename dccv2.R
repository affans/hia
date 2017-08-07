library(data.table)
library(ggplot2)
library(reshape2)
library(ggthemes)
library(plyr)

#readLines("dcc.dat", n = 2)
dcc = fread("dcc.dat", sep=",")
csts = fread("costs.dat", sep=",")

## hs == 5  implies invasive.. see parameters.jl file for ENUM values.
hs = 5
ff = dcc[health==hs, .(cnt = length(ID), avg = length(ID)/500, year = ceiling(systime/365)),  by=.(systime, agegroup)]
ff = ff[order(year), .(yearsum = sum(avg)), by = .(year, agegroup)]

## one particular agegroup
gg = ggplot(subset(ff, agegroup == 1)) 
gg = gg + geom_line(aes(year, yearsum, group=factor(agegroup), colour=factor(agegroup)))
gg

## all agegroups on a single plot
gg = ggplot(ff) 
gg = gg + geom_line(aes(year, yearsum, group=factor(agegroup), colour=factor(agegroup)))
gg


### WAIFU matrix
t = dcc[health == 2, .(cnt = length(ID)), by=.(agegroup, sickfrom)]
t[, csum := sum(cnt), by=agegroup]
t[, cavg := cnt/csum]
t = t[order(agegroup, sickfrom)]

ggplot(data = t, aes(y = factor(agegroup), x = factor(sickfrom))) +
  geom_tile(aes(fill = cavg)) + scale_fill_gradient(low = "white",high = "steelblue")+ geom_text(aes(label = round(cavg, 3))) 
 
dev.off()
heatmap.2(t)

