%%%% Coherence with fMRI data

%% We are now going to calculate the coherence and channel capacity using 
% Hsu, Borst, Theunissen methodology for some fMRI voxel data.

% First we will load data from three voxels. The voxels are from visual
% cortex, recording during stimulation with natural movies. The 486 sec
% movie was repeated 10 times. One voxel has good signal to noise, another
% average, and the last bad signal to noise.
load ../data/vox_data.mat

%% As with the psths, average the even and odd trials, average all the 
%  trials, vor each voxel.
vox_av_even = mean(vox_av(:,2:2:10),2);
vox_av_odd = mean(vox_av(:,1:2:10),2);
vox_av_mean = mean(vox_av,2);

vox_good_even = mean(vox_good(:,2:2:10),2);
vox_good_odd = mean(vox_good(:,1:2:10),2);
vox_good_mean = mean(vox_good,2);

vox_bad_even = mean(vox_bad(:,2:2:10),2);
vox_bad_odd = mean(vox_bad(:,1:2:10),2);
vox_bad_mean = mean(vox_bad,2);

%% choose a voxel to work with
vox = vox_good';
vox_mean = vox_good_mean';
vox_even = vox_good_even';
vox_odd = vox_good_odd';
vox_pred = vox_good_pred';

%% Assignment.  First plot the ave response and one or two trials - to give you a sense of the data. 
% Then calculate the Noise, its spectral density (is it white) and its
% amplitude distribution (is it normal).
t = 1:size(vox,2);
ntrials = size(vox,1);
trials = 1:ntrials;

figure
hold on
plot(t, vox)
plot(t, vox_mean, 'LineWidth', 2)

%% Calculate the noise
signal = vox_mean;
noise = vox - repmat(signal, ntrials, 1);

noise_tot = [];
noise_d1_tot = [];
signal_tot = [];
for itrial=1:ntrials
    
    % Calculate the two estimates of the noise
    noise_d1(itrial, :) = vox(itrial, :) - mean(vox(find(trials ~= itrial),:), 1);

    noise_tot = [noise_tot noise(itrial, :)];
    noise_d1_tot = [noise_d1_tot noise_d1(itrial, :)];
    
    % Plot the noises
    if (itrial == 1)
        figure
        hold on
        plot(noise_d1(itrial, :), 'r--');
        plot(noise(itrial,:), 'r');
        
        % Plot the signal
        plot(signal, 'b');
        hold off;
    end
end

%% Is the noise white?
TR = 1;
fs = 1/TR; 
window = [];
nfft = 486;
 % There are many different algorithms for estimating a power spectral
 % density.  The simplest is the periodogram that divides the time series
 % into non-overlapping chunkds of size nfft (in points) and multiplies
 % that segment with the weights given by the window.  If window is null,
 % periodogram uses a rectangular window.
%[Pnoise,f] = periodogram(noise_tot,window,nfft,fs);
%[Pnoise_d1,f] = periodogram(noise_d1_tot,window,nfft,fs);
%[Psignal,f] = periodogram(signal_tot,window,nfft,fs);

% Another methods is to use overlapping chunks - this is called Welch's
% method.  Here window can be the number of points (usually equal to nfft)
% of a hamming window or a vector of weights. noverlap is the number of
% points in the overlapp. If noverlap is [], it is set to nfft/2.
% [Pxx,f] = pwelch(x,window,noverlap,nfft,fs).  You will see that using the
% hamming window gives a smoother 


window = 486;
% window = ones(1,nfft); % square window
noverlap = [];
% noverlap = 0;
nfft = 486;
nw = 3;

%[Pnoise, f] = periodogram(noise_tot,[], window, fs);

[Pnoise, f] = pwelch(noise_tot, window, noverlap, nfft, fs);
[Pnoise_d1, f] = pwelch(noise_d1_tot, window, noverlap, nfft, fs);
[Psignal, f] = pwelch(signal, window, noverlap, nfft, fs);

%[Pnoise,f] = pmtm(noise_tot, nw, nfft,fs);
%[Pnoise_d1,f] = pmtm(noise_d1_tot, nw, nfft,fs);
%[Psignal,f] = pmtm(signal_tot, nw, nfft,fs);

figure;
plot(f, 10*log10(Pnoise), 'r');
hold on;
plot(f, 10*log10(Pnoise_d1), 'r--');
plot(f, 10*log10(Psignal), 'k');
legend('Noise', 'Noise D1', 'Signal');
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
hold off;

% We can also display the signal to noise ratio.
figure;
plot(f, log10(Psignal./Pnoise), 'k');
hold on;
plot(f, log10(Psignal./Pnoise_d1), 'k--');
ylabel('SNR');
xlabel('Frequency (Hz)');

%% Is the noise Gaussian?
figure;
histfit(10*log10(Pnoise))
xlabel('Power (dB)')
title('Noise')

figure;
histfit(10*log10(Pnoise_d1))
xlabel('Power (dB)')
title('Noise D1')


%% we're going to make a copy of the average response and corrupt
% it with Gaussian noise, pretending it's a response that comes from
% some model
noiseGain = 1; %play with gain to increase or decrease PSTH corruption
gaussNoise = randn(size(vox_mean)) * noiseGain; %make some noise!
vox_meanNoisy = vox_mean + gaussNoise; %corrupt response

%% finally, we're going to compute the upper bound of coherence, as
% for the voxel itself, as well as the coherence between the noise-
% corrupted response and actual response

infoFreqCutoff = -1; %max frequency in Hz to compute coherence for
infoWindowSize = 50; %window size in seconds to compute coherence FFT. The default in compute_coherence_full is 500 ms.
numStimPresentations = 10;
fmri_sampling_rate = 1;        % This BOLD signal has a 1 Hz sampling rate

[cBound, cModel] = compute_coherence_full(vox_meanNoisy, vox_mean, vox_even,...
					  vox_odd, fmri_sampling_rate, numStimPresentations,...
					  infoFreqCutoff, infoWindowSize);

performanceRatio = cModel.info / cBound.info; %how well did our noisy psth do?

%% now we'll make some plots of the coherence values, solid lines
% are the upper bounds, dotted lines are noisy PSTHs
figure; hold on;
plot(cBound.f, cBound.c, 'k-', 'LineWidth', 2);
plot(cBound.f, cBound.cUpper, 'b-', 'LineWidth', 2);
plot(cBound.f, cBound.cLower, 'r-', 'LineWidth', 2);

plot(cModel.f, cModel.c, 'k--', 'LineWidth', 2);
plot(cModel.f, cModel.cUpper, 'b--', 'LineWidth', 2);
plot(cModel.f, cModel.cLower, 'r--', 'LineWidth', 2);
xlabel('Frequency (Hz)');
ylabel('Coherence');
theTitle = sprintf('Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
		   cModel.info, cBound.info, performanceRatio);
title(theTitle);
axis([min(cBound.f), max(cBound.f), 0, 1]);


%% Now we're going to compute coherence with a response that does come from a model
%  of visual cortex created by the Gallant lab. The model predictions are the variables
%  that end in "_pred", i.e. vox_pred

infoFreqCutoff = -1; %max frequency in Hz to compute coherence for
infoWindowSize = 50; %window size in seconds to compute coherence FFT.  The default in compute_coherence_full is 500 ms.
numStimPresentations = 10;
fmri_sampling_rate = 1;        % This BOLD signal has a 1 Hz sampling rate

[cBound, cModel] = compute_coherence_full(vox_pred, vox_mean, vox_even,...
					  vox_odd, fmri_sampling_rate, numStimPresentations,...
					  infoFreqCutoff, infoWindowSize);

performanceRatio = cModel.info / cBound.info; %how well did our noisy psth do?

%% now we'll make some plots of the coherence values, solid lines
% are the upper bounds, dotted lines are noisy PSTHs
figure; hold on;
plot(cBound.f, cBound.c, 'k-', 'LineWidth', 2);
plot(cBound.f, cBound.cUpper, 'b-', 'LineWidth', 2);
plot(cBound.f, cBound.cLower, 'r-', 'LineWidth', 2);

plot(cModel.f, cModel.c, 'k--', 'LineWidth', 2);
plot(cModel.f, cModel.cUpper, 'b--', 'LineWidth', 2);
plot(cModel.f, cModel.cLower, 'r--', 'LineWidth', 2);
xlabel('Frequency (Hz)');
ylabel('Coherence');
theTitle = sprintf('Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
		   cModel.info, cBound.info, performanceRatio);
title(theTitle);
axis([min(cBound.f), max(cBound.f), 0, 1]);

%% How about coherence between the mean signal and the response from a
% single trial

infoFreqCutoff = -1; %max frequency in Hz to compute coherence for
infoWindowSize = 50; %window size in seconds to compute coherence FFT.  The default in compute_coherence_full is 500 ms.
numStimPresentations = 10;
fmri_sampling_rate = 1;        % This BOLD signal has a 1 Hz sampling rate
sample_trial = 2;

[cBound, cModel] = compute_coherence_full(vox(sample_trial,:), vox_mean, vox_even,...
					  vox_odd, fmri_sampling_rate, numStimPresentations,...
					  infoFreqCutoff, infoWindowSize);

performanceRatio = cModel.info / cBound.info; %how well did our noisy psth do?

%% now we'll make some plots of the coherence values, solid lines
% are the upper bounds, dotted lines are noisy PSTHs
figure; hold on;
plot(cBound.f, cBound.c, 'k-', 'LineWidth', 2);
plot(cBound.f, cBound.cUpper, 'b-', 'LineWidth', 2);
plot(cBound.f, cBound.cLower, 'r-', 'LineWidth', 2);

plot(cModel.f, cModel.c, 'k--', 'LineWidth', 2);
plot(cModel.f, cModel.cUpper, 'b--', 'LineWidth', 2);
plot(cModel.f, cModel.cLower, 'r--', 'LineWidth', 2);
xlabel('Frequency (Hz)');
ylabel('Coherence');
theTitle = sprintf('Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
		   cModel.info, cBound.info, performanceRatio);
title(theTitle);
axis([min(cBound.f), max(cBound.f), 0, 1]);


%% Now coherence between trial response and mean signal for all trials

infoFreqCutoff = -1; %max frequency in Hz to compute coherence for
infoWindowSize = 50; %window size in seconds to compute coherence FFT.  The default in compute_coherence_full is 500 ms.
numStimPresentations = 10;
fmri_sampling_rate = 1;        % This BOLD signal has a 1 Hz sampling rate

for itrial=1:ntrials
    
    [cBound, cModel] = compute_coherence_full(vox(itrial,:), vox_mean, vox_even,...
        vox_odd, fmri_sampling_rate, numStimPresentations,...
        infoFreqCutoff, infoWindowSize);
    
    performanceRatio = cModel.info / cBound.info; %how well did our noisy psth do?
    
    modelInfo(itrial,1) = cModel.info;
    boundInfo(itrial,1) = cBound.info;
    infoRatio(itrial,1) = performanceRatio;
    
end

figure
hold on
bar(1,mean(modelInfo),.5)
errorbar(mean(modelInfo),std(modelInfo)./sqrt(ntrials))
plot(mean(boundInfo),'+g','MarkerSize',25)
xlim([0 2])
theTitle = sprintf('Average Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
		   mean(modelInfo), mean(boundInfo), mean(infoRatio));
title(theTitle);



