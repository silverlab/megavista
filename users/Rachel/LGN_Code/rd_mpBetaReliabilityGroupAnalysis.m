% rd_mpBetaReliabilityGroupAnalysis.m


%% setup
scanner = '7T';
analysisExtension = 'indivScanBetaReliability';
hemis = [1 2];

plotFigs = 1;
saveFigs = 0;
saveAnalysis = 0;

[subjectDirs3T subjectDirs7T] = rd_lgnSubjects;

switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
    case '7T'
        subjectDirs = subjectDirs7T;
end

% subjects = 1:size(subjectDirs,1);
subjects = [1:4 5 7:8 10]; % 7T
% subjects = [1 2 4 5]; % 3T
nSubjects = numel(subjects);

%% show subjects
fprintf('\nSubjects to analyze:')
for iSubject = subjects
    fprintf('\n%s', subjectDirs{iSubject, 1})
end
fprintf('\n\n')

%% File I/O
analysisSaveName = 'groupIndivScanBetaCorrelations';
fileBaseDir = '/Volumes/Plata1/LGN/Group_Analyses';
fileBaseSubjects = sprintf('%s_N%d', scanner, nSubjects);
fileBaseTail = sprintf('%s',datestr(now,'yyyymmdd'));
    
%% get data from each subject
for iSubject = 1:nSubjects
    subject = subjects(iSubject)
    
    for iHemi = 1:length(hemis)
        hemi = hemis(iHemi);
        
        filePath = rd_getAnalysisFilePath(subjectDirs, scanner, ...
            subject, hemi, analysisExtension);

        data = load(filePath);
        
        vals = data.runPairCorrVals; % [n run pairs x nconds (M, P, M-P)]
        
        % different numbers of runs for each subject, so use a cell array
        groupData.runPairCorrVals{iSubject}(:,:,iHemi) = vals;
        
        % mean for each subject
        groupData.runPairCorrMeans(iSubject,:,iHemi) = mean(vals);
        
        % std for each subject
        groupData.runPairCorrStds(iSubject,:,iHemi) = std(vals);
        
        % median for each subject
        groupData.runPairCorrMedians(iSubject,:,iHemi) = median(vals);
        
        % 95% bounds of the data for each subject
        groupData.runPairCorr95PctBounds(:,:,iSubject,iHemi) = prctile(vals,[2.5 97.5]);
    end
end

%% plot summary figure for individual subjects
correlationType = data.correlationType;
condNames = data.condNames;
nConds = numel(condNames);

ylims = [-0.3 1];
xlims = [0 nSubjects+1];

hemiLabels = {'left LGN','right LGN'};
hemiNudges = [-0.1 0.1];
hemiColors = {[0 0 205]./255, [0 128 0]./255};

%% fig: mean and std
for iCond = 1:nConds
    f(1,iCond) = figure;
    hold on
    for iHemi = 1:length(hemis)
        errorbar((1:nSubjects)+hemiNudges(iHemi), ...
            groupData.runPairCorrMeans(:,iCond,iHemi), ...
            groupData.runPairCorrStds(:,iCond,iHemi),'.', ...
            'Color', hemiColors{iHemi})
    end
    plot(xlims,[0 0],'--k')
    xlim(xlims)
    ylim(ylims)
    
    set(gca,'XTick',1:nSubjects)
    xlabel('subject')
    ylabel('mean run-to-run beta correlation')
    title(condNames{iCond})
    legend(hemiLabels)
end

%% fig: median and 95% bounds
for iCond = 1:nConds
    f(2,iCond) = figure;
    hold on
    for iHemi = 1:length(hemis)
        errorL = squeeze(groupData.runPairCorr95PctBounds(1,iCond,:,iHemi)) - ...
            groupData.runPairCorrMedians(:,iCond,iHemi);
        errorU = squeeze(groupData.runPairCorr95PctBounds(2,iCond,:,iHemi)) - ...
            groupData.runPairCorrMedians(:,iCond,iHemi);
        
        errorbar((1:nSubjects)+hemiNudges(iHemi), ...
            groupData.runPairCorrMedians(:,iCond,iHemi), ...
            errorL, errorU, '.','Color', hemiColors{iHemi})
    end
    plot(xlims,[0 0],'--k')
    xlim(xlims)
    ylim([-0.3 1.1])
    
    set(gca,'XTick',1:nSubjects)
    xlabel('subject')
    ylabel('median run-to-run beta correlation')
    title(condNames{iCond})
    legend(hemiLabels)
end

%% save figs
figNames = {'mean','median'};
if saveFigs
    for iF = 1:size(f,1) %% need to add something for hemi
        for iCond = 1:nConds
            figStr = sprintf('%s_%s_beta%s', correlationType, figNames{iF}, condNames{iCond});
            plotSavePath = sprintf('%s/figures/%s_%s_%s_%s',...
                fileBaseDir, analysisSaveName, fileBaseSubjects, figStr, fileBaseTail);
            print(f(iF,iCond),'-djpeg','-r80',sprintf(plotSavePath));
        end
    end
end

%% save analysis
if saveAnalysis
    save(sprintf('%s/%s_%s_%s.mat',...
        fileBaseDir, analysisSaveName, fileBaseSubjects, fileBaseTail), ...
        'groupData', ... %'groupMean','groupStd','groupSte',...
        'correlationType','condNames', ...
        'scanner','subjectDirs','subjects','hemis');
end
