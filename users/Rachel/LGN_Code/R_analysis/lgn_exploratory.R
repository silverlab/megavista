# lgn_exploratory.R

# set working directory
setwd('/Volumes/Plata1/LGN_Localizer/Scans/MAS_20100212_session/Run02_MoreCoverage/MAS_20100212-2_MC/ROIAnalysis/')

# read in data (another time try read.table)
#roi <- read.csv('dat_files/lgnROI1-2_AvgScan1-4_20101028.dat', header=FALSE)
roi <- read.csv('dat_files/lgnROI3_AvgScan1-4_20101028.dat', header=FALSE)
roi <- read.csv('dat_files/lgnROI3_AvgScan1-6_20101029.dat', header=FALSE)

# set up time series
TR <- 3
roi <- ts(data=roi, start=TR, frequency=1/TR)
t <- ts(data=1:dim(roi)[1]*TR, start=TR, frequency=1/TR)

# stim params
stim_freq = 1/30
stim_freq_TR = stim_freq*TR

# time series mean
roi_mean <- apply(X = roi, MARGIN = 1, FUN = mean)
roi_mean <- ts(data=roi_mean, start=TR, frequency=1/TR)

# plot all voxels and mean tseries
matplot(roi, type="l", xlab='Time (TRs)', ylab='% signal change')
matlines(roi_mean, type="l", lwd=3)

# trying out some basic stats
summary(roi_mean)

qqnorm(roi_mean)
qqline(roi_mean)

roi_mean_diff <- diff(roi_mean, lag=1, differences=1)
plot(roi_mean_diff, xlab='Time (TRs)', ylab='Lag 1 difference', type='l')

lag.plot(roi_mean, lags=16)

acf(roi_mean)
pacf(roi_mean)
 
arima(roi_mean)
myspec <- spectrum(roi_mean)


# let's try fitting a sine wave regression for the mean signal
reg1 = cos(2*pi*stim_freq*t)
reg2 = sin(2*pi*stim_freq*t)

fit <- lm(roi_mean ~ 0 + reg1 + reg2) # 0 since no intercept
fit_sum <- summary(fit)

ste <- fit_sum$coefficients[,2]
tval <- fit_sum$coefficients[,3]
pval <- fit_sum$coefficients[,4]

beta = fit$coefficients
phase = atan(-beta[2]/beta[1])
amp = beta[1]/cos(phase)
vals = amp*cos(2*pi*stim_freq*t + phase)

#fitted_values = ts(data=fit$fitted.values, start=TR, frequency=1/TR)
#fitted_values2 = beta[1]*cos(2*pi*stim_freq*t) + beta[2]*sin(2*pi*stim_freq*t)

plot(roi_mean)
lines(vals, type='o')





#######################
# general useful stuff
#######################

# make a new figure
quartz()

# clear all
rm(list = ls())

# save the current figure
dev.copy2pdf(file='fname.pdf')
pdf('mygraph.pdf')

# read dat file
roi3mts <- read.csv('dat_files/roi3MTS_vox3-14-19-24.dat', header = FALSE)

# write mat file
writeMat('mat_files/sigVoxROIIdx.mat', roi1_idx=roi1_idx, roi2_idx=roi2_idx)

# install and load matlab packages
install.packages("R.matlab")
hbLite(c("R.oo", "R.utils"), CRAN=TRUE)
library("R.matlab")

library(gplots)
plotCI