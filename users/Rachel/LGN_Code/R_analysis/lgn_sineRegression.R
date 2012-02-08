# sine wave regression
#
# assume roi data and stim params are already in the workspace

reg1 = cos(2*pi*stim_freq*t)
reg2 = sin(2*pi*stim_freq*t)

nvox = dim(roi)[2]

fit_ste <- matrix(data=NA, nrow=2, ncol=nvox, byrow = FALSE)
fit_tval <- matrix(data=NA, nrow=2, ncol=nvox, byrow = FALSE)
fit_pval <- matrix(data=NA, nrow=2, ncol=nvox, byrow = FALSE)

fit_beta <- matrix(data=NA, nrow=2, ncol=nvox, byrow = FALSE)
fit_phase <- matrix(data=NA, nrow=1, ncol=nvox, byrow = FALSE)
fit_amp <- matrix(data=NA, nrow=1, ncol=nvox, byrow = FALSE)
fit_vals <- matrix(data=NA, nrow=length(t), ncol=nvox, byrow = FALSE)

for(vox in 1:nvox){

fit <- lm(roi[,vox] ~ 0 + reg1 + reg2) # 0 since no intercept
fit_sum <- summary(fit)

ste <- fit_sum$coefficients[,2]
tval <- fit_sum$coefficients[,3]
pval <- fit_sum$coefficients[,4]

beta = fit$coefficients
phase = atan(-beta[2]/beta[1])
amp = beta[1]/cos(phase)
vals = amp*cos(2*pi*stim_freq*t + phase)

fit_ste[,vox] <- ste
fit_tval[,vox] <- tval
fit_pval[,vox] <- pval

fit_beta[,vox] <- beta
fit_phase[vox] <- phase
fit_amp[vox] <- amp
fit_vals[,vox] <- vals

}

fit_vals <- ts(data=fit_vals, start=TR, frequency=1/TR)
resids = roi - fit_vals

# can change all amps to positive so phase-amp combos are unique
# change phases to match, and then make aure all remaining phases are positive
fit_amp_pos <- fit_amp
fit_amp_pos[fit_amp<0] <- fit_amp_pos[fit_amp<0]*(-1)
fit_phase_pos = fit_phase
fit_phase_pos[fit_amp<0] <- fit_phase_pos[fit_amp<0] + pi
fit_phase_pos[fit_phase_pos<0] <- fit_phase_pos[fit_phase_pos<0] + 2*pi


# plot
sample_vox = 1
plot(roi[,sample_vox])
lines(fit_vals[,sample_vox], col='red')

# check resids
sqe <- colMeans(resids[,sig_amp_idx]^2)
mean(sqe)

par(mfrow=c(1,2))
sample_vox = 2
sample_vox = sig_amp_idx[4]
qqnorm(resids[,sample_vox])
qqline(resids[,sample_vox])
dev.copy2pdf(file='figures/R_figs/roi3_residQQNorm_vox2_vox59.pdf')

plot(resids[,sample_vox], ylab='% signal change', main='Residuals')
spectrum(resids[,sample_vox], main='Residuals periodogram')
dev.copy2pdf(file='figures/R_figs/roi3_residTSeriesPeriodogram_vox2.pdf')

plot(1:nvox,fit_pval[1,])
points(1:21,fit_pval[2,], col='blue')
abline(.05,0)


