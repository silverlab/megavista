% rd_compareIndivRunStats
%
% compares run-by-run F, var exp, and behav data

hemi = 2;

saveAnalysis = 1;
saveFigs = 1;

%% file i/o
fFiles = dir(sprintf('lgnROI%d_%s', hemi, 'fTests_run*'));
varExpFile = dir(sprintf('lgnROI%d_%s', hemi, 'indivScanData_timeCourse*'));
behavFile = '../../Behavior/behavAcc.mat';

nRuns = numel(fFiles);

analysisFile = sprintf('lgnROI%d_indivRunStats_%s', hemi, datestr(now,'yyyymmdd'));
figFileBase = sprintf('figures/lgnROI%dScatter_indivRuns', hemi);

%% get F data
clear fOverallMeans fCondMeans fCondThreshedMeans
for iRun = 1:nRuns
    load(fFiles(iRun).name)

    fOverallMeans(:,:,iRun) = F.overallMean;
    fCondMeans(:,:,iRun) = F.condMean;
    fCondThreshedMeans(:,:,iRun) = F.condThreshedMean;
end
delays = hemoDelays;
nDelays = numel(delays);

%% get var exp data
if numel(varExpFile) ~= 1
    error('Too few or too many varExpFiles')
end
load(varExpFile(1).name)

clear varExp
for iRun = 1:nRuns
    varExp(iRun) = uiData(iRun).tc.glm.varianceExplained;
end

%% get behav data
load(behavFile)
overallAcc = acc.overallAcc;
condAcc = acc.condAcc(:,1:2);

%% plot comparisons
msize = 12;

%% F overall mean (each delay) vs average behav performance 
f(1) = figure('Position',[0 0 900 250]);
for iDelay = 1:nDelays
    subplot(1,nDelays,iDelay)
    plot(overallAcc, squeeze(fOverallMeans(1,iDelay,:)), '.k', 'MarkerSize', msize)
    title(sprintf('Delay = %d TR', delays(iDelay)))
    if iDelay==1
        xlabel('behav overall acc')
        ylabel('overall F')
    end
    axis square
end
rd_supertitle(sprintf('Hemi %d', hemi))

%% F cond mean (each delay) vs cond behav performance 
f(2) = figure('Position',[0 0 900 250]);
for iDelay = 1:nDelays
    subplot(1,nDelays,iDelay)
    hold on
    plot(condAcc(:,1), squeeze(fCondMeans(iDelay,1,:)), '.r', 'MarkerSize', msize)
    plot(condAcc(:,2), squeeze(fCondMeans(iDelay,2,:)), '.b', 'MarkerSize', msize)
    title(sprintf('Delay = %d TR', delays(iDelay)))
    if iDelay==1
        xlabel('behav cond acc')
        ylabel('cond F')
        legend('M','P','Location','best')
    end
    axis square
end
rd_supertitle(sprintf('Hemi %d', hemi))

%% F cond threshed mean (each delay) vs cond behav performance
f(3) = figure('Position',[0 0 900 250]);
for iDelay = 1:nDelays
    subplot(1,nDelays,iDelay)
    hold on
    plot(condAcc(:,1), squeeze(fCondThreshedMeans(iDelay,1,:)), '.r', 'MarkerSize', msize)
    plot(condAcc(:,2), squeeze(fCondThreshedMeans(iDelay,2,:)), '.b', 'MarkerSize', msize)
    title(sprintf('Delay = %d TR', delays(iDelay)))
    if iDelay==1
        xlabel('behav cond acc')
        ylabel(sprintf('cond threshed F, prop = %.02f', threshProp))
        legend('M','P','Location','best')
    end
    axis square
end
rd_supertitle(sprintf('Hemi %d', hemi))

%% F overall mean (each delay) vs var exp
f(4) = figure('Position',[0 0 900 250]);
for iDelay = 1:nDelays
    subplot(1,nDelays,iDelay)
    plot(varExp, squeeze(fOverallMeans(1,iDelay,:)), '.k', 'MarkerSize', msize)
    title(sprintf('Delay = %d TR', delays(iDelay)))
    if iDelay==1
        xlabel('variance explained')
        ylabel('overall F')
    end
    axis square
end
rd_supertitle(sprintf('Hemi %d', hemi))

%% Var exp vs average behav performance
f(5) = figure('Position',[0 0 250 250]);
plot(overallAcc, varExp, '.k', 'MarkerSize', msize)
xlabel('behav overall acc')
ylabel('variance explained')
title(sprintf('Hemi %d', hemi))
axis square

%% Save analysis
if saveAnalysis
    save(analysisFile, 'overallAcc','condAcc','fOverallMeans','fCondMeans',...
        'fCondThreshedMeans','varExp','delays');
end

%% Save figs
if saveFigs
    figNames = {'overallF_vs_meanBehavAcc',...
        'condF_vs_condBehavAcc',...
        'condThreshedF_vs_condBehavAcc',...
        'overallF_vs_varExp',...
        'varExp_vs_meanBehavAcc'};
    figsToSave = 1:numel(figNames);
    
    for iF = figsToSave
        figFile = sprintf('%s_%s_%s', figFileBase, figNames{iF}, datestr(now,'yyyymmdd'));
        print(f(iF), '-djpeg', figFile)
    end
end

%% Get vars from allData (from every subject, generated in rd_runIndivAnalysis)
fOverallMeans = allData.fOverallMeans;
fCondMeans = allData.fCondMeans;
fCondThreshedMeans = allData.fCondThreshedMeans;
varExp = allData.varExp;
overallAcc = allData.overallAcc;
condAcc = allData.condAcc;
delays = [0 1 2 3];
nDelays = numel(delays);
threshProp = .1;
groupFigDir = '/Volumes/Plata1/LGN/Group_Analyses/figures';
figFileBase = sprintf('%s/groupIndivRuns_%s_N%d_hemi%d', ...
    groupFigDir, scanner, nSubjects, hemi)
saveFigs = 1

