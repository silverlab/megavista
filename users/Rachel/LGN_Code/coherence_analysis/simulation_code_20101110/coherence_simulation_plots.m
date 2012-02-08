% coherence_simulation_plots.m

noiseGains = [.5 1 2];
infoWindows = [30 40 50];
nTrials = [4 8 16];
nTrialsLog = log2(nTrials);

infoWindowLabels = {'30','40','50'};

%% SNR
figure
varName = 'SNR';
dataIndex = find(strcmp((cohSimData_headers), varName));
for iNoise=1:3
    subplot(1,numel(noiseGains),iNoise)
    plot(nTrialsLog,squeeze(cohSimData(:,dataIndex,:,iNoise)))
    
    xlabel('log2(number of trials)')
    title(['Noise gain = ' num2str(noiseGains(iNoise))])
    
    set(gca,'XTick', nTrialsLog)
    
    if iNoise==1
        ylabel(varName)
    elseif iNoise==numel(noiseGains)
        legend(infoWindowLabels)
    end
  
end

%% model ratio
figure
varName = 'modelRatio';
dataIndex = find(strcmp((cohSimData_headers), varName));
for iNoise=1:3
    subplot(1,numel(noiseGains),iNoise)
    plot(nTrialsLog,squeeze(cohSimData(:,dataIndex,:,iNoise)))
    
    xlabel('log2(number of trials)')
    title(['Noise gain = ' num2str(noiseGains(iNoise))])
    
    set(gca,'XTick', nTrialsLog)
    ylim([.75 1])
    
    if iNoise==1
        ylabel(varName)
    elseif iNoise==numel(noiseGains)
        legend(infoWindowLabels)
    end
  
end

%% trial ratio
figure
varName = 'trialRatio';
dataIndex = find(strcmp((cohSimData_headers), varName));
for iNoise=1:3
    subplot(1,numel(noiseGains),iNoise)
    plot(nTrialsLog,squeeze(cohSimData(:,dataIndex,:,iNoise)))
    
    xlabel('log2(number of trials)')
    title(['Noise gain = ' num2str(noiseGains(iNoise))])
    
    set(gca,'XTick', nTrialsLog)
    ylim([.3 1])
    
    if iNoise==1
        ylabel(varName)
    elseif iNoise==numel(noiseGains)
        legend(infoWindowLabels)
    end
  
end