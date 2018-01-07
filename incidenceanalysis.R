library(data.table)
library(ggplot2)
library(reshape2)
library(ggthemes)
library(plyr)
library(gridExtra)
library(grid)
library(RColorBrewer)

# This R file is for plotting purposes only.

## install all packages by supplying a column vector
# ipak <- function(pkg){
#   new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
#   if (length(new.pkg)) 
#     install.packages(new.pkg, dependencies = TRUE)
#   #sapply(pkg, require, character.only = TRUE)
# }
# 
# # usage
# packages <- c("ggplot2", "plyr", "reshape2", "RColorBrewer", "scales", "grid", "data.table", "ggthemes", "gridExtra")
# ipak(packages)

## incidence for the first 30 years
sdcc =  fread("./sep05/nolf/dcc_seed.dat", sep=",")
##incidence with vaccine @ 77% coverage
vdcc =  fread("./sep05/nolf/dcc_vaccine.dat", sep=",")
##incidence with vaccine @ 90% coverage
vdcc90 = fread("./sep05/nolf/dcc_vaccine_90.dat", sep=",")
##incidence with no vaccine
tdcc =  fread("./sep05/nolf/dcc_thirty.dat", sep=",")

#####################################
## Overall Incidence - only seed   ##
##################################### 
## for each age group, get the daily average, and create a new column  "year" corresponding to 1 to 30
ff = sdcc[health==5, .(cnt = length(ID), avg = length(ID)/500, year = ceiling(systime/365)),  by=.(systime)]
## sum up the averages per day for each year, per age group
ff = ff[order(year), .(yearsum = sum(avg)), by = .(year)]
## change year to factor
ff <- ff[, year:=as.factor(year)]

# Plot ONLY seed data with mean after 10 calculated
## get the mean after 10 years to 30 years
ff[,  maf:= round(mean(yearsum[10:23]), 3)]
gg = ggplot(ff)
gg = gg + geom_line(aes(year, yearsum, group=1), linetype=1)
gg = gg + geom_line(aes(year, maf, group=1), linetype='dashed')
gg = gg + geom_point(aes(year, yearsum, group=1), size=3, alpha=1) ##pch=21 for only border cirlce
gg = gg + ggtitle("Overall - Invasive") + xlab("Time (in years)") + ylab("Incidence") + theme_minimal()
gg = gg + theme(panel.grid.minor = element_blank())
gg = gg + theme(axis.line = element_line(colour = "black"))
#gg = gg + scale_colour_manual(values=c("#e41a1c","#377eb8","#4daf4a","#984ea3","#ff7f00"))
gg = gg + scale_x_discrete(breaks=seq(10, 50, by=5), labels = seq(10, 50, by=5))
gg = gg + theme(legend.position="none")
gg


######################################
## Overall Incidence - +thirty      ##
###################################### 
# change vdcc to vdcc90 if 90% coverage data is used
######################################

## for each age group, get the daily average, and create a new column  "year" corresponding to 1 to 30
ff = sdcc[health==5, .(cnt = length(ID), avg = length(ID)/500, year = ceiling(systime/365)),  by=.(systime)]
## sum up the averages per day for each year, per age group
ff = ff[order(year), .(yearsum = sum(avg)), by = .(year)]
#ff <- ff[, year:=as.factor(year)] ## change year to factor

fv = vdcc[health==5, .(cnt = length(ID), avg = length(ID)/500, year = (ceiling(systime/365) + 30)),  by=.(systime)]
## sum up the averages per day for each year, per age group
fv = fv[order(year), .(yearsum = sum(avg)), by = .(year)]
## dont change to factor.. ggplot does "alphabetical order" on x axes. 
## ie, 1, 10,11, .. 2, 20, 21..messes up the plot
#fv <- fv[, year:=as.factor(year)] ## change year to factor
fv = rbind(ff[30, ], fv) ## bind last year of seed for continuous graph

## get the vaccine data
## for each age group, get the daily average, and create a new column  "year" corresponding to 1 to 30
ft = tdcc[health==5, .(cnt = length(ID), avg = length(ID)/500, year = (ceiling(systime/365) + 30)),  by=.(systime)]
## sum up the averages per day for each year, per age group
ft = ft[order(year), .(yearsum = sum(avg)), by = .(year)]
#ft = ft[, year:=as.factor(year)] ## change year to factor
ft = rbind(ff[30, ], ft) ## bind last year of seed for continuous graph

gg = ggplot()
gg = gg + geom_line(data=ff, aes(year, yearsum, group=1), linetype="solid", size=1.25 )
gg = gg + geom_point(data=ff, aes(year, yearsum, group=1), size=2.5)

gg = gg + geom_line(data=fv, aes(year, yearsum, group=2), linetype="twodash", size=1.25)
gg = gg + geom_point(data=fv, aes(year, yearsum, group=2), size=2.5)

gg = gg + geom_line(data=ft, aes(year, yearsum, group=3), linetype="solid", size=1.25)
gg = gg + geom_point(data=ft, aes(year, yearsum, group=3), size=2.5)

gg = gg + scale_x_continuous(expand = c(0.01, 0), breaks=seq(0, 40, by=5), labels = seq(0, 40, by=5))
gg = gg + scale_colour_manual(values=c("#e41a1c","#377eb8","#4daf4a","#984ea3","#ff7f00"))
gg = gg + scale_y_continuous(expand = c(0.01, 0), limits= c(0, 20))

gg = gg + theme_minimal()
gg = gg + theme(legend.position="none")
gg = gg + theme(axis.line = element_line(colour = "black"))
gg = gg + theme(panel.grid.minor = element_blank())

#gg = gg  + xlab("Time (in years)") + ylab("Incidence") 
gg = gg + theme(axis.line = element_line(colour = "black"))
#gg = gg +  ggtitle("Yearly Invasive")

gg = gg + theme(axis.title.x=element_blank())
gg = gg + theme(axis.title.y = element_blank())
gg = gg + theme(axis.text=element_text(size=24))
gg



##################################
## Age-Group specific incidence ##
################################## 
## for each age group, get the daily average, and create a new column  "year" corresponding to 1 to 30
ff = sdcc[health==5, .(cnt = length(ID), avg = length(ID)/500, year = ceiling(systime/365)),  by=.(systime, agegroup)]
## sum up the averages per day for each year, per age group
ff = ff[order(year), .(yearsum = sum(avg)), by = .(year, agegroup)]
## change year to factor
ff <- ff[, year:=as.factor(year)]

# Plot ONLY seed data with mean after 10 calculated
## get the mean after 10 years to 30 years
ff[,  maf:= round(mean(yearsum[10:23]), 3), by=agegroup]
legendvals = sort(ff[, paste("Ag", agegroup, ": ", max(maf), sep=""), by=agegroup]$V1)
gg = ggplot(ff)
gg = gg + geom_line(aes(year, yearsum, group=factor(agegroup), colour=factor(agegroup)), size=1, linetype=3)
gg = gg + geom_line(aes(year, maf, group=factor(agegroup), colour=factor(agegroup)), linetype='dashed')
gg = gg + geom_point(aes(year, yearsum, group=factor(agegroup), colour=factor(agegroup)), size=3, alpha=1) ##pch=21 for only border cirlce
gg = gg + scale_colour_hue(labels = legendvals)
gg = gg + labs(color='Mean after 10') + ggtitle("Yearly Latent") + xlab("Time (in years)") + ylab("Incidence") + theme_minimal()
#gg = gg + theme(panel.grid.minor = element_blank())
#gg = gg + theme(axis.line = element_line(colour = "black"))
#gg = gg + scale_colour_manual(values=c("#e41a1c","#377eb8","#4daf4a","#984ea3","#ff7f00"))
gg = gg + scale_x_discrete(breaks=seq(10, 50, by=5), labels = seq(10, 50, by=5))
#gg = gg + theme(legend.position="none")
gg
## if using scale_colour_manual, need to supply "breaks" and color "values"
##  use scale_colour_manual if using custom colour pallete


##########################
## Force of Infection   ##
##########################
w = sdcc[health == 2, .(cnt = length(ID)), by=.(agegroup, sickfrom)]
w[, csum := sum(cnt), by=agegroup]
w[, cavg := cnt/csum]
# in order:  w[order(agegroup, sickfrom)]
gg = ggplot(data = w, aes(y = factor(agegroup), x = factor(sickfrom))) 
gg = gg +   geom_tile(aes(fill = cavg)) + scale_fill_gradient(low = "white",high = "steelblue")+ geom_text(aes(label = round(cavg, 3))) 
gg = gg + labs(fill='%val') + ggtitle("Force of Infection/WAIFW") + xlab("From...") + ylab("Agegroup getting sick") + theme_minimal()
gg = gg + scale_x_discrete(position = "top") 
gg

### WAIFU matrix - seed numbers divided by vaccine numbers
w1 = sdcc[health == 2, .(cnt = length(ID)), by=.(agegroup, sickfrom)]
w1[, csum := sum(cnt), by=agegroup]
w1[, cavg := cnt/csum]
w1 = w1[order(agegroup, sickfrom)]

w2 = vdcc[health == 2, .(cnt = length(ID)), by=.(agegroup, sickfrom)]
w2[, csum := sum(cnt), by=agegroup]
w2[, cavg := cnt/csum]
w2 = w2[order(agegroup, sickfrom)]

w2[, cavgdiv := cavg/w1$cavg]

# in order:  w[order(agegroup, sickfrom)]
gg = ggplot(data = w2, aes(y = factor(agegroup), x = factor(sickfrom))) 
gg = gg +   geom_tile(aes(fill = cavgdiv)) + scale_fill_gradient(low = "white",high = "steelblue")+ geom_text(aes(label = round(cavgdiv, 3))) 
gg = gg + labs(fill='%val') + ggtitle("Force of Infection/WAIFW") + xlab("From...") + ylab("Agegroup getting sick") + theme_minimal()
gg = gg + scale_x_discrete(position = "top") 
gg = gg + labs(caption = "Force of infection: caccine FOI divided by seed FOI")
gg


##############################
## 10 YEAR EXTENSION DATA   ##
##############################
## for each age group, get the daily average, and create a new column  "year" corresponding to 1 to 30
ff = sdcc[health==5, .(cnt = length(ID), avg = length(ID)/500, year = ceiling(systime/365)),  by=.(systime, agegroup)]
## sum up the averages per day for each year, per age group
ff = ff[order(year), .(yearsum = sum(avg)), by = .(year, agegroup)]
## change year to factor
#ff <- ff[, year:=as.factor(year)]

## get the vaccine data
## for each age group, get the daily average, and create a new column  "year" corresponding to 1 to 30
fv = vdcc90[health==5, .(cnt = length(ID), avg = length(ID)/500, year = ceiling(systime/365)),  by=.(systime, agegroup)]
## sum up the averages per day for each year, per age group
fv = fv[order(year), .(yearsum = sum(avg)), by = .(year, agegroup)]
## change the year to be continuous from the seed data
fv[, year := year + 30]
fv = rbind(ff[year == 30, ], fv) ## bind last year of seed for continuous graph


## get the vaccine data
## for each age group, get the daily average, and create a new column  "year" corresponding to 1 to 30
ft = tdcc[health==5, .(cnt = length(ID), avg = length(ID)/500, year = ceiling(systime/365)),  by=.(systime, agegroup)]
## sum up the averages per day for each year, per age group
ft = ft[order(year), .(yearsum = sum(avg)), by = .(year, agegroup)]
## change the year to be continuous from the seed data
ft[, year := year + 30]
ft = rbind(ff[year == 30, ], ft) ## bind last year of seed for continuous graph

gg = ggplot()
gg = gg + geom_line(data=ff, aes(year, yearsum, group=agegroup, colour=factor(agegroup)),size=1.25)
gg = gg + geom_point(data=ff, aes(year, yearsum, group=agegroup, colour=factor(agegroup)), size=2.5, alpha=1) ##pch=21 for only border cirlce

gg = gg + geom_line(data=fv, aes(year, yearsum, group=agegroup, colour=factor(agegroup)), linetype="twodash", size=1.25)
gg = gg + geom_point(data=fv, aes(year, yearsum, group=agegroup, colour=factor(agegroup)), size=2.5, alpha=1) ##pch=21 for only border cirlce

gg = gg + geom_line(data=ft, aes(year, yearsum, group=agegroup, colour=factor(agegroup)), size=1.25, alpha=0.5)
gg = gg + geom_point(data=ft, aes(year, yearsum, group=agegroup, colour=factor(agegroup)), size=2.5, alpha=0.5) ##pch=21 for only border cirlce

gg = gg + theme_minimal()
gg = gg + theme(legend.position="none")
gg = gg + theme(panel.grid.minor = element_blank())
gg = gg + theme(axis.line = element_line(colour = "black"))
gg = gg + theme(axis.title.x=element_blank())
gg = gg + theme(axis.title.y = element_blank())
gg = gg + theme(axis.text=element_text(size=24))


#gg = gg + xlab("Time (in years)") + ylab("Incidence") 
gg = gg + scale_x_continuous(expand = c(0.01, 0), breaks=seq(0, 40, by=5), labels = seq(0, 40, by=5))
gg = gg + scale_colour_manual(values=c("#e41a1c","#377eb8","#4daf4a","#984ea3","#ff7f00"))
gg = gg + scale_y_continuous(expand = c(0.01, 0), limits= c(0, 10))

gg

#f1 = rbind(ff, fv)
#f2 = rbind(ff, ft)
#gg = gg + geom_line(data=f1, aes(factor(year), yearsum, group=agegroup, colour=factor(agegroup)), linetype="dashed")
#gg = gg + geom_line(data=f2, aes(factor(year), yearsum, group=agegroup, colour=factor(agegroup)), linetype="solid")
#gg = gg + labs(color='AgeGroup') + ggtitle("Invasive, all groups, with/without vaccine") + xlab("Year") + ylab("Incidence/100,000") + theme_minimal()
#gg = gg + labs(caption = "Solid: No vaccine \n Dashed: With vaccine")
gg


## VACCINE TREATMENT PLOTS
## check out many people got booster
i = idcc[, .(avg = length(ID)), by=dose]



## test 
sdcc[health==5 & systime == 1]


simdata = matrix(data=0, nrow = 500, ncol = 365)
for(i in 1:500){
  for(j in 1:365){
    jj = 10585 + j
    if(length(ff[systime == jj & simid == i]$cnt) > 0){
       simdata[i, j] <- ff[systime == jj & simid == i]$cnt
    } 
    #simdata[i, j] = ff[systime == jj & simid == i]$cnt
  }
}

