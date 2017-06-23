### plotting for Hia_Julia in R
rm(list = ls())
library(data.table)
library(ggplot2)
library(reshape2)
library(ggthemes)

args = commandArgs(trailingOnly=TRUE)

# Multiple plot function

# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#

makeplot <- function(plabel, seqs, vc){
  mean_after_ten = mean(vc[10:(t/365)])  ## mean after ten years - vc[10:(t/365)] takes into account t -- the total years defined above
  gg = ggplot(data.frame(time = 1:(t/365), data = vc),
              aes(x = time)) +  geom_line(aes(y=data)) + geom_point(aes(y=data)) +
    #geom_segment(aes(x=10,xend=(),y=mean_after_ten,yend=mean_after_ten))
    annotate("text", x=Inf, y=Inf, label=paste("mean(>10) =", round(mean_after_ten,4)), vjust=1, hjust=2) +
    geom_hline(yintercept=mean_after_ten, linetype="dashed", color = "red") +
    ggtitle(plabel) + xlab("Time (in years)") + ylab("Incidence") + theme_minimal()
  return(gg)
}

multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

## multiplot usage, where p1, p2, p3 are ggplots
#multiplot(p1, p2, p3, p4, cols=2)
if (length(args)==0) {
  folder = "Ag1"
} else {
  folder = args[1]
}

latent = fread(paste(folder, "/latent.dat", sep=""))
carriage = fread(paste(folder, "/carriage.dat", sep=""))
symptomatic = fread(paste(folder, "/symptomatic.dat", sep=""))
invasive = fread(paste(folder, "/invasive.dat", sep=""))
recovered = fread(paste(folder, "/recovered.dat", sep=""))
deadinv = fread(paste(folder, "/deadinvasive.dat", sep=""))


t = nrow(latent)
sims = ncol(latent)
dt = data.table(lat = numeric(t), car = numeric(t), sym = numeric(t), 
                inv = numeric(t), rec = numeric(t), dinv = numeric(t), dnat = numeric(t))


dt$lat = rowMeans(latent)
dt$car = rowMeans(carriage)
dt$sym = rowMeans(symptomatic)
dt$inv = rowMeans(invasive)
dt$rec = rowMeans(recovered)
dt$dinv = rowMeans(deadinv)

## Open PDF device
pdf(paste(folder, "_plots.pdf", sep=""), width=8.5, height=11, paper="USr")

## average annual invasive
plabel = "Yearly invasive - average"
seqs <- seq_along(dt$inv)
avgcalc = tapply(dt$inv,rep(seqs,each=365)[seqs],FUN=sum) ## sum every 365 days
gg = makeplot(plabel, seqs, avgcalc)
gg


plabel = "Death due to Invasive"
seqs <- seq_along(dt$dinv)
avgcalc = tapply(dt$dinv,rep(seqs,each=365)[seqs],FUN=sum) ## sum every 365 days
gg = makeplot(plabel, seqs, avgcalc)
gg

plabel = "Yearly latent - average"
seqs <- seq_along(dt$lat)
avgcalc = tapply(dt$lat,rep(seqs,each=365)[seqs],FUN=sum) ## sum every 365 days
gg = makeplot(plabel, seqs, avgcalc)
gg

plabel = "Yearly carriage - average"
seqs <- seq_along(dt$car)
avgcalc = tapply(dt$car,rep(seqs,each=365)[seqs],FUN=sum) ## sum every 365 days
gg = makeplot(plabel, seqs, avgcalc)
gg

plabel = "Yearly symptomatic - average"
seqs <- seq_along(dt$sym)
avgcalc = tapply(dt$sym,rep(seqs,each=365)[seqs],FUN=sum) ## sum every 365 days
gg = makeplot(plabel, seqs, avgcalc)
gg

plabel = "Yearly recovered - average"
seqs <- seq_along(dt$rec)
avgcalc = tapply(dt$rec,rep(seqs,each=365)[seqs],FUN=sum) ## sum every 365 days
gg = makeplot(plabel, seqs, avgcalc)
gg

####------------------------------
### DAILY DATA -- make plots manually
## WE DONT DO THESE>. they make the PDF file large because thats a lot of DAILY data

# plabel = "daily latent, average over sims, incidence"
# gg = ggplot(data = dt) + geom_line(aes(x = 1:t, y = lat)) +
#   ggtitle(plabel) + xlab("Time (in days)") + ylab("Incidence") + theme_minimal()
# gg
# 
# plabel = "daily carriage, average over sims, incidence"
# gg = ggplot(data = dt) + geom_line(aes(x = 1:t, y = car)) +
#   ggtitle(plabel) + xlab("Time (in days)") + ylab("Incidence") + theme_minimal()
# gg
# 
# plabel = "daily symptomatic, average over sims, incidence"
# gg = ggplot(data = dt) + geom_line(aes(x = 1:t, y = sym)) +
#   ggtitle(plabel) + xlab("Time (in days)") + ylab("Incidence") + theme_minimal()
# gg
# 
# plabel = "daily invasive, average over sims, incidence"
# gg = ggplot(data = dt) + geom_line(aes(x = 1:t, y = inv)) +
#   ggtitle(plabel) + xlab("Time (in days)") + ylab("Incidence") + theme_minimal()
# gg



### cumalative PLOTS, send to multiplots to save as one
plabel = "daily latent, average over sims, cumalative"
gg1 = ggplot(data = dt) + geom_line(aes(x = 1:t, y = cumsum(lat))) +
  ggtitle(plabel) + xlab("Time (in days)") + ylab("Prevalence") + theme_minimal()


plabel = "daily carriage, average over sims, cumalative"
gg2 = ggplot(data = dt) + geom_line(aes(x = 1:t, y = cumsum(car))) +
  ggtitle(plabel) + xlab("Time (in days)") + ylab("Prevalence") + theme_minimal()


plabel = "daily symptomatic, average over sims, cumalative"
gg3 = ggplot(data = dt) + geom_line(aes(x = 1:t, y = cumsum(sym))) +
  ggtitle(plabel) + xlab("Time (in days)") + ylab("Prevalence") + theme_minimal()

plabel = "daily invasive, average over sims, cumalative"
gg4 = ggplot(data = dt) + geom_line(aes(x = 1:t, y = cumsum(inv))) +
  ggtitle(plabel) + xlab("Time (in days)") + ylab("Prevalence") + theme_minimal()


multiplot(gg1, gg2, gg3, gg4, cols=2)
dev.off()

