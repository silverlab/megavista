# sine wave regression analysis
# 
# finds voxels with significant parameter fits, divides into ROIs based on phase, and plots data from these voxels
# assume roi data and stim params are already in the workspace, and lgn_sineRegression.R has been run

# which p-vals are < 0.05?
sig_amp_idx <- which(fit_pval[1,]<0.05)
sig_phase_idx <- which(fit_pval[2,]<0.05)

# which voxels have significant amp AND phase
sig_vox <- matrix(0, nvox, 2)
sig_vox[sig_amp_idx,1] <- 1 
sig_vox[sig_phase_idx,2] <- 1
sig_ap_idx <- which(rowSums(sig_vox)==2)

# look at the phases of these voxels
par(mfrow=c(3,1))
hist(fit_phase[sig_amp_idx], breaks=30)
hist(fit_phase[sig_phase_idx], breaks=30)
hist(fit_phase[sig_ap_idx], breaks=10)

hist(fit_phase[sig_vox[,1] & fit_amp<0], breaks = 16, xlim=c(-1,1))
hist(fit_phase[sig_vox[,1] & fit_amp>0], breaks = 16, xlim=c(-1,1))


# let's say for now that phases<0 are roi1 and phases>0 are roi2
sig_amp_roi1 <- roi[,sig_vox[,1] & fit_amp<0]
sig_amp_roi2 <- roi[,sig_vox[,1] & fit_amp>0]
sig_phase_roi1 <- roi[,sig_vox[,2] & fit_phase<0]
sig_phase_roi2 <- roi[,sig_vox[,2] & fit_phase>0]
sig_ap_roi1 <- roi[,sig_vox[,1] & sig_vox[,2] & fit_phase<0]
sig_ap_roi2 <- roi[,sig_vox[,1] & sig_vox[,2] & fit_phase>0]

# let's look at just the voxels with a sig amp and/or sig phase
sig_amp_roi1_mean <- ts(data=rowMeans(sig_amp_roi1), start=TR, frequency=1/TR)
sig_amp_roi2_mean <- ts(data=rowMeans(sig_amp_roi2), start=TR, frequency=1/TR)
sig_phase_roi1_mean <- ts(data=rowMeans(sig_phase_roi1), start=TR, frequency=1/TR)
sig_phase_roi2_mean <- ts(data=rowMeans(sig_phase_roi2), start=TR, frequency=1/TR)
sig_ap_roi1_mean <- ts(data=rowMeans(sig_ap_roi1), start=TR, frequency=1/TR)
sig_ap_roi2_mean <- ts(data=rowMeans(sig_ap_roi2), start=TR, frequency=1/TR)

# look at sine wave fits for these means
sig_amp_roi1_fit <- lm(sig_amp_roi1_mean ~ 0 + reg1 + reg2)
sig_amp_roi2_fit <- lm(sig_amp_roi2_mean ~ 0 + reg1 + reg2)
sig_phase_roi1_fit <- lm(sig_phase_roi1_mean ~ 0 + reg1 + reg2)
sig_phase_roi2_fit <- lm(sig_phase_roi2_mean ~ 0 + reg1 + reg2) 
sig_ap_roi1_fit <- lm(sig_ap_roi1_mean ~ 0 + reg1 + reg2)
sig_ap_roi2_fit <- lm(sig_ap_roi2_mean ~ 0 + reg1 + reg2)


# plot sig roi means and fits
# roi1
par(mfrow=c(3,1))
plot(sig_amp_roi1_mean)
lines(ts(data=sig_amp_roi1_fit$fitted.values, start=TR, frequency=1/TR), col='red')
plot(sig_phase_roi1_mean)
lines(ts(data=sig_phase_roi1_fit$fitted.values, start=TR, frequency=1/TR), col='red')
plot(sig_ap_roi1_mean)
lines(ts(data=sig_ap_roi1_fit$fitted.values, start=TR, frequency=1/TR), col='red')

# roi2
par(mfrow=c(3,1))
plot(sig_amp_roi2_mean)
lines(ts(data=sig_amp_roi2_fit$fitted.values, start=TR, frequency=1/TR), col='red')
plot(sig_phase_roi2_mean)
lines(ts(data=sig_phase_roi2_fit$fitted.values, start=TR, frequency=1/TR), col='red')
plot(sig_ap_roi2_mean)
lines(ts(data=sig_ap_roi2_fit$fitted.values, start=TR, frequency=1/TR), col='red')

plot(sig_amp_roi1_mean)
lines(sig_amp_roi2_mean)




