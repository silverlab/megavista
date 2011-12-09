% rd_runVoxCoherence.m

% addpath(genpath('/Volumes/Plata1/LGN_Localizer/Code/'))

voxDate = '20101118'; % More Coverage 20101110; High Res 20101118
roiNum = 2;
voxelNums = 1:34; % More Coverage ROI1: 21 voxels; ROI2: 12 voxels
                  % High Res ROI1: 61 voxels; ROI2: 34 voxels
                  % High Res Combine-4 ROI1: 15 voxels; ROI2: 8 voxels
                  % ** To use combined data, change file prefix in rd_voxCoherence.
nVox = length(voxelNums);

stimFreq = .033;

for iVox = 1:nVox
    
    [snr mcoh tcoh cb] = rd_voxCoherence(voxDate, roiNum, iVox);

    f(iVox,:) = snr.f;
    SNR(iVox,:) = snr.snr;
    SNR_d1(iVox,:) = snr.snr_d1;
    
    modelCoh.modelInfo(iVox,1) = mcoh.modelInfo;
    modelCoh.boundInfo(iVox,1) = mcoh.boundInfo;
    modelCoh.infoRatio(iVox,1) = mcoh.infoRatio;
    
    trialCoh.modelInfo(iVox,1) = mean(tcoh.modelInfo);
    trialCoh.boundInfo(iVox,1) = mean(tcoh.boundInfo);
    trialCoh.infoRatio(iVox,1) = mean(tcoh.infoRatio);
    
    cf(iVox,:) = cb.f;
    cBound.c(iVox,:) = cb.c;
    cBound.cUpper(iVox,:) = cb.cUpper;
    cBound.cLower(iVox,:) = cb.cLower;
    
end

stimFreqIdx = find(abs(f(1,:)-stimFreq)<.001);
stimFreqCohNearestIdx = find(abs(cf(1,:)-stimFreq)<.02);

%% summary plots (averages across voxels)
figure
hold on
bar(1,mean(modelCoh.modelInfo),.5)
errorbar(mean(modelCoh.modelInfo),std(modelCoh.modelInfo)./sqrt(nVox))
errorbar(mean(modelCoh.boundInfo),std(modelCoh.boundInfo)./sqrt(nVox),'g')
xlim([0 2])
theTitle = sprintf('Model Average Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
    mean(modelCoh.modelInfo), mean(modelCoh.boundInfo), mean(modelCoh.infoRatio));
title(theTitle);
fprintf('\n%s\n', theTitle)

figure
hold on
bar(1,mean(trialCoh.modelInfo),.5)
errorbar(mean(trialCoh.modelInfo),std(trialCoh.modelInfo)./sqrt(nVox))
errorbar(mean(trialCoh.boundInfo),std(trialCoh.boundInfo)./sqrt(nVox),'g')
xlim([0 2])
theTitle = sprintf('Trial Average Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
    mean(trialCoh.modelInfo), mean(trialCoh.boundInfo), mean(trialCoh.infoRatio));
title(theTitle);
fprintf('\n%s\n', theTitle)

figure
hold on
errorbar(f(1,:), mean(SNR),std(SNR)./sqrt(nVox), 'k');
errorbar(f(1,:), mean(SNR_d1),std(SNR_d1)./sqrt(nVox), 'k--');
ylabel('SNR');
xlabel('Frequency (Hz)');
theTitle = sprintf('Stim freq SNR=%0.2f, SNR D1=%0.2f', ...
    mean(SNR(:,stimFreqIdx)), mean(SNR_d1(:,stimFreqIdx)));
title(theTitle);
fprintf('\n%s\n', theTitle)

figure 
hold on
errorbar(cf(1,:), mean(cBound.c), std(cBound.c)./sqrt(nVox), 'k-', 'LineWidth', 2);
errorbar(cf(1,:), mean(cBound.cUpper), std(cBound.cUpper)./sqrt(nVox), 'b-', 'LineWidth', 2);
errorbar(cf(1,:), mean(cBound.cLower), std(cBound.cLower)./sqrt(nVox), 'r-', 'LineWidth', 2);
xlabel('Frequency (Hz)');
ylabel('Coherence');
theTitle = sprintf('Expected coherence - ROI %s-%d', voxDate, roiNum);
title(theTitle);
axis([min(cf(1,:)), max(cf(1,:)), 0, 1]);
legend('mean','upper bound','lower bound')


%% plots by voxel
figure
hold on
scatter(voxelNums, SNR(:,stimFreqIdx), 'k')
scatter(voxelNums, modelCoh.modelInfo, 'g')
scatter(voxelNums, modelCoh.infoRatio, 'r')

minSNR = min(SNR(:,stimFreqIdx));
maxSNR = max(SNR(:,stimFreqIdx));
SNR_norm = (SNR(:,stimFreqIdx) - minSNR)./(maxSNR - minSNR);
modelCoh_mInfo_norm = (modelCoh.modelInfo - min(modelCoh.modelInfo))./...
    (max(modelCoh.modelInfo) - min(modelCoh.modelInfo));
modelCoh_infoRatio_norm = (modelCoh.infoRatio - min(modelCoh.infoRatio))./...
    (max(modelCoh.infoRatio) - min(modelCoh.infoRatio));

lineOfEquality = 0:.01:1;

figure
subplot(1,3,1)
hold on
scatter(SNR_norm, modelCoh_mInfo_norm, 60, voxelNums, '.')
plot(lineOfEquality, lineOfEquality, 'k')
xlabel('Normalized SNR')
ylabel('Normalized Model Info')
axis square

subplot(1,3,2)
hold on
scatter(SNR_norm, modelCoh_infoRatio_norm, 60, voxelNums, '.')
plot(lineOfEquality, lineOfEquality, 'k')
xlabel('Normalized SNR')
ylabel('Normalized Model Info Ratio')
axis square

subplot(1,3,3)
hold on
scatter(modelCoh_mInfo_norm, modelCoh_infoRatio_norm, 60, voxelNums, '.')
plot(lineOfEquality, lineOfEquality, 'k')
xlabel('Normalized Model Info')
ylabel('Normalized Model Info Ratio')
axis square

