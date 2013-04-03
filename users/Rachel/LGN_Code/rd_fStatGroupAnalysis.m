% rd_fStatGroupAnalysis.m

%% setup
[subjectDirs3T subjectDirs7T] = rd_lgnSubjects;
            
scanner = '7T';
analysisExtension = 'fTests_2*';
hemis = [1 2];

plotFigs = 1;
saveAnalysis = 0;

MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
colors = {MCol, PCol};

switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
    case '7T'
        subjectDirs = subjectDirs7T;
end

subjects = 1:4;
% subjects = 1:size(subjectDirs,1);
nSubjects = numel(subjects);
            
%% get data from each subject
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    for iHemi = 1:length(hemis)
        hemi = hemis(iHemi);
        
        filePath = rd_getAnalysisFilePath(subjectDirs, scanner, ...
            subject, hemi, analysisExtension);

        data = load(filePath);
        
        overallMean = data.F.overallMean;
        condMean = data.F.condMean;
        condThreshedMean = data.F.condThreshedMean;
        threshIdx = data.F.threshIdx;
        
        fOverallMean(iSubject,:,iHemi) = overallMean;
        fCondMean(:,:,iSubject,iHemi) = condMean;
        fCondThreshedMean(:,:,iSubject,iHemi) = condThreshedMean;
        nVox(iSubject,iHemi) = size(data.F.overall,1);
        nVoxSuperthresh(iSubject,iHemi) = threshIdx;
        
    end
end

% group summary stats
g.fOverallMean = squeeze(mean(fOverallMean,1)); % [delay x hemi]
g.fCondMean = squeeze(mean(fCondMean,3)); % [delay x cond x hemi]
g.fCondThreshedMean = squeeze(mean(fCondThreshedMean,3)); % [delay x cond x hemi]

g.fOverallStd = squeeze(std(fOverallMean,0,1)); % [delay x hemi]
g.fCondStd = squeeze(std(fCondMean,0,3)); % [delay x cond x hemi]
g.fCondThreshedStd = squeeze(std(fCondThreshedMean,0,3)); % [delay x cond x hemi]


%% plot figs
if plotFigs
    plotDelays = repmat(data.hemoDelays',1,2);
    cushion = .1*range(data.hemoDelays);
    xlims = [plotDelays(1)-cushion plotDelays(end)+cushion];
    figure
    for iHemi = 1:numel(hemis)
        subplot(1,numel(hemis),iHemi)
        hold on
        p1 = errorbar(plotDelays, g.fCondMean(:,:,iHemi), g.fCondStd(:,:,iHemi)/sqrt(nSubjects));
        p2 = errorbar(plotDelays, g.fCondThreshedMean(:,:,iHemi), g.fCondThreshedStd(:,:,iHemi)/sqrt(nSubjects));
        set(p1(1), 'Color', colors{1}, 'DisplayName', 'M all')
        set(p1(2), 'Color', colors{2}, 'DisplayName', 'P all')
        set(p2(1), 'Color', colors{1}, 'LineWidth', 2, 'DisplayName', 'M top 10%')
        set(p2(2), 'Color', colors{2}, 'LineWidth', 2, 'DisplayName', 'P top 10%')
        xlabel('delay (TRs)')
        ylabel('F-statistic')
        title(sprintf('Hemi %d', iHemi))
        xlim(xlims)
        axis square
        legend show
    end
end

%% save analysis
if saveAnalysis
    save(sprintf('/Volumes/Plata1/LGN/Group_Analyses/groupFStat_%s_N%d_%s.mat',...
        scanner, nSubjects, datestr(now,'yyyymmdd')), ...
        'g', 'fOverallMean', 'fCondMean', 'fCondThreshedMean', ...
        'nVox', 'nVoxSuperthresh', 'scanner', ...
        'subjectDirs', 'subjects', 'hemis');
end

