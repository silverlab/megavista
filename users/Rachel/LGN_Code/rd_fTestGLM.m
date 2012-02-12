% rd_fTestGLM.m

%% Setup
hemi = 1;
roiName = 'ROI X01'; % 'sphere_4mm';

hemoDelays = 0:3; % 0:3
nDelays = length(hemoDelays);

saveFigs = 1;

package = 'mrVista'; % 'SPM', 'mrVista'

figFileBase = sprintf('lgnROI%dBars', hemi);
fBlockFigSavePath = sprintf('figures/%s_fBlock%s', figFileBase, datestr(now,'yyyymmdd'));


switch package
    case 'SPM'
        %% File I/O
        tSeriesFile = sprintf('ROIAnalysis/%s/%s_roi%d_ts.mat', roiName, roiName, hemi);
        blockOrderFile = 'condorder.mat';
        
        %% Load data and get tseries from each voxel
        data = load(tSeriesFile);
        tSeries = data.voxTS;
        
        %% Read conditions from blockOrder file
        design = load(blockOrderFile);
        condNames = design.names;
        blockOrder = design.condOrder;

    case 'mrVista'
        blocksPerRun = 15;
        multiVoxFile = sprintf('lgnROI%d_multiVoxFigData.mat', hemi);
        dataDesign = load(multiVoxFile);
        
        condNames = dataDesign.figData.trials.condNames;
        tSeries = dataDesign.figData.tSeries;
        blockOrder = dataDesign.figData.trials.cond;
        blockOrder(blocksPerRun+1:blocksPerRun+1:end) = []; % mrVista adds an 'end of run' label for the last TR of the run
        blockOrder = blockOrder + 1; % mrVista also uses zero indexing for condition numbers
    
    otherwise
        error('Package not recognized.')
end

%% A few more initializations
figTitle = sprintf('%s, hemi %d', roiName, hemi);
nConditions = length(condNames);
blankCond = find(strcmp(condNames,'blank'));
stimConds = 1:nConditions;
stimConds(blankCond) = [];
stimCondNames = condNames(stimConds);

%% Calculate f stats across all conditions
for iDelay = 1:nDelays
    hemoDelay = hemoDelays(iDelay);
    
    fBlock = rd_fTestBlockGLM(tSeries, blockOrder, hemoDelay, [], figTitle);

    fBlockMean(iDelay) = mean(fBlock);
    fBlockMax(iDelay) = max(fBlock);

    fprintf('\nhemoDelay = %d:\n', hemoDelay)
    disp([fBlockMean(iDelay); fBlockMax(iDelay)])
end

%% Plot mean f by hemoDelay
figure
bar(hemoDelays,fBlockMean)
xlabel('delay (TRs)')
ylabel('f statistic')
title(figTitle)

%% Calculate f stats for each stim condition compared to blank
for iDelay = 1:nDelays
    hemoDelay = hemoDelays(iDelay);
    
    for iCond = 1:length(stimCondNames) % compare each stim cond to blank cond
        condName = stimCondNames{iCond};
        blockTypes = [stimConds(iCond) blankCond];
        temp = rd_fTestBlockGLM(tSeries, blockOrder, ...
            hemoDelay, blockTypes, [figTitle ', ' condName]);
        fBlockByCond(:,iCond) = temp;
    end

    fBlockByCondMean(iDelay, :) = mean(fBlockByCond,1);
    fBlockByCondMax(iDelay, :) = max(fBlockByCond,[],1);
end

%% Plot mean condition fs by hemoDelay
for iDelay = 1:nDelays
    delayNames{iDelay} = sprintf('%d TR delay',hemoDelays(iDelay));
end

figure
bar(fBlockByCondMean')
set(gca,'XTickLabel',stimCondNames)
xlabel('stim condition vs. blank')
ylabel('f statistic')
title(figTitle)
legend(delayNames)

% check f-stats (std? var?), make f-test scatter plots (m vs p)

if saveFigs
    print(gcf, '-dtiff', fBlockFigSavePath)
end

