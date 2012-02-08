# sine wave regression analysis
# 
# finds voxels with significant parameter fits, divides into ROIs based on phase, and plots data from these voxels
# assume roi data and stim params are already in the workspace, and lgn_sineRegression.R has been run

# plot acf for select voxel
par(mfrow=c(1,2))
acf(roi3mts[,3], main='Raw')
acf(roi3mtsp[,3], main='Detrended')
dev.copy2pdf(file='figures/detrend_figs/roi3_vox0019_detrendACF2.pdf')

# plot amps and phases with standard errors
par(mfrow=c(1,1))
plotCI(fit_phase_pos, fit_amp_pos, fit_ste[1,], xlab='phase', ylab='amplitude', main='Parameter estimates')
plotCI(fit_phase_pos, fit_amp_pos, fit_ste[1,], err='x', add=TRUE)
dev.copy2pdf(file='figures/R_figs/roi3_phaseAmp_paramEstimates.pdf')

# which p-vals are < 0.05? (only amp matters, we don't care if phase is different from zero)
sig_amp_idx <- which(fit_pval[1,]<0.05)

# which voxels have significant amp
sig_vox <- matrix(0, nvox, 1)
sig_vox[sig_amp_idx,1] <- 1 

# look at the phases of these voxels
par(mfrow=c(2,1))
hist(fit_phase[sig_vox[,1] & fit_amp<0], breaks = 16, xlim=c(-1,1))
hist(fit_phase[sig_vox[,1] & fit_amp>0], breaks = 16, xlim=c(-1,1))

par(mfrow=c(1,1))
hist(fit_phase_pos[sig_vox[,1]==1], breaks = 30, xlim=c(0,2*pi), main='Voxels with amplitude fit p<0.05', xlab='Phase')
dev.copy2pdf(file='figures/R_figs/roi1-2p_sig_vox_phases.pdf')

# let's say for now that amp<0 are roi1 and amp>0 are roi2, sig amp voxels only
roi1 <- roi[,sig_vox[,1] & fit_amp<0]
roi2 <- roi[,sig_vox[,1] & fit_amp>0]

# roi means
roi1_mean <- ts(data=rowMeans(roi1), start=TR, frequency=1/TR)
roi2_mean <- ts(data=rowMeans(roi2), start=TR, frequency=1/TR)

# look at sine wave fits for these means
roi1_fit <- lm(roi1_mean ~ 0 + reg1 + reg2)
roi2_fit <- lm(roi2_mean ~ 0 + reg1 + reg2)

# plot sig amp roi means and fits
par(mfrow=c(2,1))
plot(roi1_mean)
lines(ts(data=roi1_fit$fitted.values, start=TR, frequency=1/TR), col='red')
plot(roi2_mean)
lines(ts(data=roi2_fit$fitted.values, start=TR, frequency=1/TR), col='red')

plot(roi1_mean)
lines(roi2_mean)


# now let's divide into rois based on positive-restricted phase, sig amp voxels only
roi1p <- roi[,sig_vox[,1] & fit_phase_pos>2 & fit_phase_pos<5]
roi2p <- roi[,sig_vox[,1] & (fit_phase_pos<2 | fit_phase_pos>5)]

# roi means
roi1p_mean <- ts(data=rowMeans(roi1p), start=TR, frequency=1/TR)
roi2p_mean <- ts(data=rowMeans(roi2p), start=TR, frequency=1/TR)

# look at sine wave fits for these means
roi1p_fit <- lm(roi1p_mean ~ 0 + reg1 + reg2)
roi2p_fit <- lm(roi2p_mean ~ 0 + reg1 + reg2)

# plot sig amp roi means and fits
par(mfrow=c(2,1))
plot(roi1p_mean, main='Mean time series and model fit - population 1', ylab='% signal change')
lines(ts(data=roi1p_fit$fitted.values, start=TR, frequency=1/TR), col='red')
plot(roi2p_mean, main='Mean time series and model fit - population 2', ylab='% signal change')
lines(ts(data=roi2p_fit$fitted.values, start=TR, frequency=1/TR), col='red')
dev.copy2pdf(file='figures/R_figs/roi1-2p_tseries_fits.pdf')

par(mfrow=c(1,1))
plot(roi1p_mean, main='Mean time series and model fits', ylab='% signal change')
lines(roi2p_mean)
lines(ts(data=roi1p_fit$fitted.values, start=TR, frequency=1/TR), col='red')
lines(ts(data=roi2p_fit$fitted.values, start=TR, frequency=1/TR), col='blue')
legend('topright', c('Population 1','Population 2'),col=c('red','blue'),pch=c('-','-'))
dev.copy2pdf(file='figures/R_figs/roi1-2p_tseries_fits_overlay.pdf')

plot(roi1p_mean)
lines(roi2p_mean)

# ** it turns out that roi and roip are the same! **
# which voxels are these? 
roi1_idx = which(sig_vox[,1] & fit_phase_pos>2 & fit_phase_pos<5)
roi2_idx = which(sig_vox[,1] & (fit_phase_pos<2 | fit_phase_pos>5))

# store their pvals and tvals and phases
roi1_pval = fit_pval[1,roi1_idx]
roi2_pval = fit_pval[1,roi2_idx]

roi1_tval = abs(fit_tval[1,roi1_idx])
roi2_tval = abs(fit_tval[1,roi2_idx])

roi1_phase = fit_phase_pos[roi1_idx]
roi2_phase = fit_phase_pos[roi2_idx]

# save roi data to mat file
writeMat('mat_files/sigVoxROIData.mat', roi1_idx=roi1_idx, roi2_idx=roi2_idx, roi1_pval=roi1_pval, roi2_pval=roi2_pval, roi1_tval=roi1_tval, roi2_tval=roi2_tval, roi1_phase=roi1_phase, roi2_phase=roi2_phase)

