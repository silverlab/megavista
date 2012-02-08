% function [SNR, modelCoh, trialCoh] = rd_voxCoherence
function [SNR, modelCoh, trialCoh, cBound] = rd_voxCoherence(voxDate, roiNum, voxNum)
% rd_voxCoherence.m
%
% Coherence analysis on data from individual voxels over several runs.

% addpath(genpath('/Volumes/Plata1/LGN_Localizer/Code/'))

plotfigs = 0;

%% Vox info / load data
% voxDate = '20101110';
% roiNum = 1;
% voxNum = 9; 
voxDir = 'vox_data';

voxID = sprintf('%s_roi%02d_vox%05d', voxDate, roiNum, voxNum);
dataFile = sprintf('%s/voxdata_%s.mat', voxDir, voxID);

load(dataFile); % loads 'vox'

%% Data collection params
nTrials = 6; % number of runs (4 or 6)
nCycles = 8; % number of cycles per run (8)
nTRsPerCycle = 10; % number of TRs per cycle (10)
TR = 3; % TR duration (3 secs)

nTRsPerTrial = nCycles*nTRsPerCycle;
trials = 1:nTrials;

%% Generate the model (sine wave) time series
t = 1:nTRsPerTrial;
amp = 1;
phase = 0;
freq = 1/nTRsPerCycle*(2*pi);

vox0 = amp*sin(freq*t + phase);

%% Vox means
vox_mean = mean(vox, 1);
vox_even = mean(vox(2:2:nTrials,:), 1);
vox_odd = mean(vox(1:2:nTrials,:), 1);

if plotfigs
    figure
    hold on
    p1 = plot(t, vox);
    plot(t, vox_mean, 'LineWidth', 2)
    plot(t, vox0, '--k', 'LineWidth', 2)
    for iP1 = 1:length(p1)
        set(get(get(p1(iP1),'Annotation'),'LegendInformation'),...
            'IconDisplayStyle','off');
    end
    legend('Mean', 'Model')
    xlabel('Time (TRs)')
    ylabel('% signal change')
end

%% Calculate the noise
signal = vox_mean;
noise = vox - repmat(signal, nTrials, 1);

noise_tot = [];
noise_d1_tot = [];
signal_tot = [];
for iTrial=1:nTrials
    
    % Calculate the two estimates of the noise
    noise_d1(iTrial, :) = vox(iTrial, :) - mean(vox(find(trials ~= iTrial),:), 1);

    noise_tot = [noise_tot noise(iTrial, :)];
    noise_d1_tot = [noise_d1_tot noise_d1(iTrial, :)];
    
    % Plot the noises
    if (iTrial == 1) && plotfigs
        figure
        hold on
        plot(noise_d1(iTrial, :), 'r--');
        plot(noise(iTrial,:), 'r');
        
        % Plot the signal
        plot(signal, 'b');
        hold off;
        legend('Noise D1', 'Noise', 'Signal')
        xlabel('Time (TRs)')
        ylabel('% signal change')
    end
end

%% Is the noise white?

% There are many different algorithms for estimating a power spectral
% density.  The simplest is the periodogram that divides the time series
% into non-overlapping chunkds of size nfft (in points) and multiplies
% that segment with the weights given by the window.  If window is null,
% periodogram uses a rectangular window.

% fs = 1/TR; 
% window = [];
% nfft = nTRsPerTrial;
% [Pnoise,f] = periodogram(noise_tot,window,nfft,fs);
% [Pnoise_d1,f] = periodogram(noise_d1_tot,window,nfft,fs);
% [Psignal,f] = periodogram(signal_tot,window,nfft,fs);

% Another methods is to use overlapping chunks - this is called Welch's
% method.  Here window can be the number of points (usually equal to nfft)
% of a hamming window or a vector of weights. noverlap is the number of
% points in the overlapp. If noverlap is [], it is set to nfft/2.
% [Pxx,f] = pwelch(x,window,noverlap,nfft,fs).  You will see that using the
% hamming window gives a smoother 

fs = 1/TR; 
window = nTRsPerTrial;
% window = ones(1,nfft); % square window
noverlap = [];
% noverlap = 0;
nfft = nTRsPerTrial;
% nw = 3;

%[Pnoise, f] = periodogram(noise_tot,[], window, fs);

[Pnoise, f] = pwelch(noise_tot, window, noverlap, nfft, fs);
[Pnoise_d1, f] = pwelch(noise_d1_tot, window, noverlap, nfft, fs);
[Psignal, f] = pwelch(signal, window, noverlap, nfft, fs);

%[Pnoise,f] = pmtm(noise_tot, nw, nfft,fs);
%[Pnoise_d1,f] = pmtm(noise_d1_tot, nw, nfft,fs);
%[Psignal,f] = pmtm(signal_tot, nw, nfft,fs);

if plotfigs
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
    legend('Noise', 'Noise D1');
    ylabel('SNR');
    xlabel('Frequency (Hz)');
end

SNR.f = f;
SNR.snr = log10(Psignal./Pnoise);
SNR.snr_d1 = log10(Psignal./Pnoise_d1);

%% Is the noise Gaussian?
if plotfigs
    figure;
    histfit(Pnoise)
    % histfit(10*log10(Pnoise))
    xlabel('Power')
    title('Noise')
    
    figure;
    histfit(Pnoise_d1)
    % histfit(10*log10(Pnoise_d1))
    xlabel('Power')
    title('Noise D1')
end

%% Coherence calculations param initializations
infoFreqCutoff = -1; % max frequency in Hz to compute coherence for
infoWindowSize = 40; % window size in seconds to compute coherence FFT.  The default in compute_coherence_full is 500 ms.
numStimPresentations = nTrials;
fmri_sampling_rate = 1/TR;        

%% Now we're going to compute coherence with a response that comes from the
% sine wave model
[cBound, cModel] = compute_coherence_full(vox0, vox_mean, vox_even,...
					  vox_odd, fmri_sampling_rate, numStimPresentations,...
					  infoFreqCutoff, infoWindowSize);

performanceRatio = cModel.info / cBound.info; %how well did our noisy psth do?

modelCoh.modelInfo = cModel.info;
modelCoh.boundInfo = cBound.info;
modelCoh.infoRatio = performanceRatio;
    
%% now we'll make some plots of the coherence values, solid lines
% are the upper bounds, dotted lines are noisy PSTHs
% upper and lower bounds are two standard deviations away from the mean
if plotfigs
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
end

%% How about coherence between the mean signal and the response from a
% single trial
sample_trial = 1;

[cBound, cModel] = compute_coherence_full(vox(sample_trial,:), vox_mean, vox_even,...
					  vox_odd, fmri_sampling_rate, numStimPresentations,...
					  infoFreqCutoff, infoWindowSize);

performanceRatio = cModel.info / cBound.info; %how well did our noisy psth do?

%% now we'll make some plots of the coherence values, solid lines
% are the upper bounds, dotted lines are noisy PSTHs
if plotfigs
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
end


%% Now coherence between trial response and mean signal for all trials
for iTrial=1:nTrials
    
    [cBound, cModel] = compute_coherence_full(vox(iTrial,:), vox_mean, vox_even,...
        vox_odd, fmri_sampling_rate, numStimPresentations,...
        infoFreqCutoff, infoWindowSize);
    
    performanceRatio = cModel.info / cBound.info; %how well did our noisy psth do?
    
    trialCoh.modelInfo(iTrial,1) = cModel.info;
    trialCoh.boundInfo(iTrial,1) = cBound.info;
    trialCoh.infoRatio(iTrial,1) = performanceRatio;
    
end

if plotfigs
    figure
    hold on
    bar(1,mean(trialCoh.modelInfo),.5)
    errorbar(mean(trialCoh.modelInfo),std(trialCoh.modelInfo)./sqrt(nTrials))
    plot(mean(trialCoh.boundInfo),'+g','MarkerSize',25)
    xlim([0 2])
    theTitle = sprintf('Average Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
        mean(trialCoh.modelInfo), mean(trialCoh.boundInfo), ...
        mean(trialCoh.infoRatio));
    title(theTitle);
end


