% rd_fStatGroupAnalysis.m

%% setup
subjectDirs3T = {'AV_20111117_session', 'AV_20111117_n', 'ROIX01';
                'AV_20111128_session', 'AV_20111128_n', 'ROIX01/Runs1-9';
                'CG_20120130_session', 'CG_20120130_n_LOW', 'ROIX01';
                'CG_20120130_session', 'CG_20120130_n_HIGH', 'ROIX01';
                'RD_20120205_session', 'RD_20120205_n', 'ROIX01'};
            
subjectDirs7T = {'KS_20111212_Session', 'KS_20111212_15mm', 'ROIX01';
                'AV_20111213_Session', 'AV_20111213', 'ROIX01';
                'KS_20111214_Session', 'KS_20111214', 'ROIX01';
                'RD_20111214_Session', 'RD_20111214', 'ROIX01'};
            
scanner = '7T';

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

subjects = 1:size(subjectDirs,1);
nSubjects = numel(subjects);

for iSubject = 1:nSubjects
    subjectIDs{iSubject} = subjectDirs{iSubject,2};
end
            
%% get data from each subject
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    for iHemi = 1:length(hemis)
        hemi = hemis(iHemi);
        
        subjectDir{1} = subjectDirs{subject,1};
        subjectDir{2} = subjectDirs{subject,2};
        subjectDir{3} = subjectDirs{subject,3};
        
        fileDirectory = sprintf('/Volumes/Plata1/LGN/Scans/%s/%s/%s/ROIAnalysis/%s',...
            scanner, subjectDir{1}, subjectDir{2}, subjectDir{3});
        
        fileBase = sprintf('lgnROI%d', hemi);
        analysisExtension = 'fTests_*';
        
        dataDir = dir(sprintf('%s/%s_%s.mat', ...
            fileDirectory, fileBase, analysisExtension));
        fileName = dataDir.name;
        
        data = load(sprintf('%s/%s', fileDirectory, fileName));
        
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

