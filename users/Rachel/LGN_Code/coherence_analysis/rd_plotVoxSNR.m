% rd_plotVoxSNR.m
%
% run rd_runVoxCoherence first or load 'SNR','voxelNums','stimFreqIdx'
% later will need to load z-score data from lgn pipeline

%% more SNR plots by voxel
SNR_stim = SNR(:,stimFreqIdx);
SNR_nonstim = SNR;
SNR_nonstim(:,stimFreqIdx) = [];
SNR_nonstim_mean = mean(SNR_nonstim,2);
SNR_diff = SNR_stim - SNR_nonstim_mean;

figure
hold on
plot(voxelNums, SNR_stim)
plot(voxelNums, mean(SNR_nonstim,2),'g')
legend('stim freq','non-stim freqs')
xlabel('Voxel number')
ylabel('SNR')

figure
b1 = bar(voxelNums, [SNR_stim SNR_nonstim_mean]);
legend('stim freq','non-stim freqs')
xlabel('Voxel number')
ylabel('SNR')
set(b1,'BaseValue',-1)
hold on
plot(voxelNums, zeros(size(voxelNums)), '--k')

%% compare to zscores - load roi data from lgn pipeline
% load('lgnROI1-2Data_AvgScan1-6_20101118')
% data = data2; % data1 / data2

zScores = nan(nVox,1);
for iSet = 1:length(data)
    zScores(:,iSet) = data{iSet}.zScore; 
end

zScores = reshape(zScores,nVox,1);

figure
hold on
scatter(SNR_diff, zScores)
xlabel('SNR difference (stim - nonstim)')
ylabel('fft z-score')

xgrid = [min(SNR_diff):.1:max(SNR_diff)];
p = polyfit(SNR_diff, zScores, 1);
fit = polyval(p, xgrid);
plot(xgrid, fit, 'k')

rZDiff = corrcoef(SNR_diff, zScores);
rZDiff = rZDiff(1,2);
title(sprintf('r = %.02f', rZDiff))

%% compare to expected (split-half) coherence
cBoundC_stim = mean(cBound.c(:,stimFreqCohNearestIdx),2);
cBoundC_nonstim = cBound.c;
cBoundC_nonstim(:,stimFreqCohNearestIdx) = [];
cBoundC_nonstim_mean = mean(cBoundC_nonstim,2);
cBoundC_diff = cBoundC_stim - cBoundC_nonstim_mean;

figure
hold on
scatter(cBoundC_stim, zScores)
xlabel('Expected coherence (stim freq)')
ylabel('FFT z-score')

figure
hold on
scatter(cBoundC_diff, zScores)
xlabel('Expected coherence (stim - nonstim)')
ylabel('FFT z-score')






