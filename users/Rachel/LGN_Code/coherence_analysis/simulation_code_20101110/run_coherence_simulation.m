% run_coherence_simulation

ntrials = 100;

for itrial = 1:ntrials
    
    [snr mcoh tcoh] = coherence_simulation;
%     [snr mcoh tcoh] = coherence_simulation(ntrials, nCycles, noiseGain, infoWindowSize);
    
    f(itrial,:) = snr.f;
    SNR(itrial,:) = snr.snr;
    SNR_d1(itrial,:) = snr.snr_d1;
    
    modelCoh.modelInfo(itrial,1) = mcoh.modelInfo;
    modelCoh.boundInfo(itrial,1) = mcoh.boundInfo;
    modelCoh.infoRatio(itrial,1) = mcoh.infoRatio;
    
    trialCoh.modelInfo(itrial,1) = mean(tcoh.modelInfo);
    trialCoh.boundInfo(itrial,1) = mean(tcoh.boundInfo);
    trialCoh.infoRatio(itrial,1) = mean(tcoh.infoRatio);
    
end

figure
hold on
bar(1,mean(modelCoh.modelInfo),.5)
errorbar(mean(modelCoh.modelInfo),std(modelCoh.modelInfo)./sqrt(ntrials))
errorbar(mean(modelCoh.boundInfo),std(modelCoh.boundInfo)./sqrt(ntrials),'g')
xlim([0 2])
theTitle = sprintf('Model Average Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
    mean(modelCoh.modelInfo), mean(modelCoh.boundInfo), mean(modelCoh.infoRatio));
title(theTitle);
fprintf('\n%s\n', theTitle)

figure
hold on
bar(1,mean(trialCoh.modelInfo),.5)
errorbar(mean(trialCoh.modelInfo),std(trialCoh.modelInfo)./sqrt(ntrials))
errorbar(mean(trialCoh.boundInfo),std(trialCoh.boundInfo)./sqrt(ntrials),'g')
xlim([0 2])
theTitle = sprintf('Trial Average Info=%0.2f bits/s out of %0.2f bits/s | Ratio=%0.2f', ...
    mean(trialCoh.modelInfo), mean(trialCoh.boundInfo), mean(trialCoh.infoRatio));
title(theTitle);
fprintf('\n%s\n', theTitle)


figure
hold on
errorbar(f(1,:), mean(SNR),std(SNR)./sqrt(ntrials), 'k');
errorbar(f(1,:), mean(SNR_d1),std(SNR_d1)./sqrt(ntrials), 'k--');
ylabel('SNR');
xlabel('Frequency (Hz)');
theTitle = sprintf('Peak SNR=%0.2f, SNR D1=%0.2f', ...
    max(mean(SNR)), max(mean(SNR_d1)));
title(theTitle);
fprintf('\n%s\n', theTitle)
