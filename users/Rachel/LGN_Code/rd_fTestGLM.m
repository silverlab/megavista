% rd_fTestGLM.m

%% Setup
hemi = 2;
% roiName = 'ROIX01'; % 'sphere_4mm';

hemoDelays = 0:3; % 0:3
nDelays = length(hemoDelays);

threshProp = .1; 

saveAnalysis = 1;
saveFigs = 0; % don't save figs when using uiData, will overwrite previous

package = 'mrVista'; % 'SPM', 'mrVista'
dataStorage = 'uiData'; % 'figData', 'uiData' (relevant to mrVista only)
% iScan = 1; % scan index for uiData

MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
colors = {MCol, PCol};

fileBase = sprintf('lgnROI%d', hemi);
if strcmp(package,'mrVista') && strcmp(dataStorage,'uiData')
    analysisSavePath = sprintf('%s_fTests_run%02d_%s.mat', ...
        fileBase, iScan, datestr(now,'yyyymmdd'));
else
    analysisSavePath = sprintf('%s_fTests_%s.mat', fileBase, datestr(now,'yyyymmdd'));
end
fPlotFigSavePath = sprintf('figures/%sPlot_fBlockMP_%s', fileBase, datestr(now,'yyyymmdd'));
fScatterFigSavePath = sprintf('figures/%sScatter_fBlockMP_%s', fileBase, datestr(now,'yyyymmdd'));

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
        
        switch dataStorage
            case 'figData'
                multiVoxFile = sprintf('lgnROI%d_multiVoxFigData.mat', hemi);
                dataDesign = load(multiVoxFile);
                figData = dataDesign.figData;
            case 'uiData'
                multiVoxFiles = dir(sprintf('lgnROI%d_indivScanData_multiVoxel*', hemi));
                if numel(multiVoxFiles)~=1
                    error('Too many or too few data files found.')
                end
                dataDesign = load(multiVoxFiles.name);
                figData = dataDesign.uiData(iScan).mv;
            otherwise
                error('dataStorage not recognized.')
        end
        
        condNames = figData.trials.condNames;
        tSeries = figData.tSeries;
        blockOrder = figData.trials.cond;
        blockOrder(blocksPerRun+1:blocksPerRun+1:end) = []; % mrVista adds an 'end of run' label for the last TR of the run
        blockOrder = blockOrder + 1; % mrVista also uses zero indexing for condition numbers
    
    otherwise
        error('Package not recognized.')
end

%% A few more initializations
figTitle = sprintf('Hemi %d', hemi);
nConditions = length(condNames);
blankCond = find(strcmp(condNames,'blank'));
stimConds = 1:nConditions;
stimConds(blankCond) = [];
stimCondNames = condNames(stimConds);
nVox = size(tSeries,2);

%% Calculate f stats across all conditions
fBlock = nan(nVox,nDelays);
for iDelay = 1:nDelays
    hemoDelay = hemoDelays(iDelay);
    
%     fBlock = rd_fTestBlockGLM(tSeries, blockOrder, hemoDelay, [], figTitle);
    fBlock(:,iDelay) = rd_fTester(tSeries, blockOrder, hemoDelay, [], 1, figTitle);
end

fBlockMean = mean(fBlock); % [1 x delay]
fBlockMax = max(fBlock);

% print results
for iDelay = 1:nDelays
    fprintf('\nhemoDelay = %d:\n', hemoDelay)
    disp([fBlockMean(iDelay); fBlockMax(iDelay)])
end

%% Plot mean f by hemoDelay
figure
bar(hemoDelays,fBlockMean)
xlabel('delay (TRs)')
ylabel('F statistic')
title(figTitle)

%% Calculate f stats for each stim condition compared to blank
fBlockByCond = nan(nVox,length(stimCondNames),nDelays);
for iDelay = 1:nDelays
    hemoDelay = hemoDelays(iDelay);
    
    for iCond = 1:length(stimCondNames) % compare each stim cond to blank cond
        condName = stimCondNames{iCond};
        blockTypes = [stimConds(iCond) blankCond];
%         temp = rd_fTestBlockGLM(tSeries, blockOrder, ...
%             hemoDelay, blockTypes, [figTitle ', ' condName]);
        temp = rd_fTester(tSeries, blockOrder, ...
            hemoDelay, blockTypes, 1, [figTitle ', ' condName]);
        fBlockByCond(:,iCond,iDelay) = temp;
    end
end

fBlockByCondMean = squeeze(mean(fBlockByCond,1))'; % [delay x cond]
fBlockByCondMax = squeeze(max(fBlockByCond,[],1))';
fBlockByCondStd = squeeze(std(fBlockByCond,1))';

% Look at top voxels
nVox = size(fBlockByCond,1);
threshIdx = round(nVox*threshProp);
fBlockByCondS = sort(fBlockByCond,1,'descend'); % sorts each column independently
fBlockByCondThreshed = fBlockByCondS(1:threshIdx,:,:);
fBlockByCondThreshedMean = squeeze(mean(fBlockByCondThreshed,1))'; % [delay x cond]
fBlockByCondThreshedStd = squeeze(std(fBlockByCondThreshed,1))';

%% Save data
F.overall = fBlock;
F.overallMean = fBlockMean;
F.overallMax = fBlockMax;
F.cond = fBlockByCond;
F.condMean = fBlockByCondMean;
F.condMax = fBlockByCondMax;
F.condStd = fBlockByCondStd;
F.threshIdx = threshIdx;
F.condSorted = fBlockByCondS;
F.condThreshed = fBlockByCondThreshed;
F.condThreshedMean = fBlockByCondThreshedMean;
F.condThreshedStd = fBlockByCondThreshedStd;

if saveAnalysis
    save(analysisSavePath,'F','hemi','hemoDelays','threshProp')
end

%% Plot mean condition fs by hemoDelay
delayNames = cell(1,nDelays);
for iDelay = 1:nDelays
    delayNames{iDelay} = sprintf('%d TR delay',hemoDelays(iDelay));
end

% all voxels
figure
bar(fBlockByCondMean')
set(gca,'XTickLabel',stimCondNames)
xlabel('stim condition vs. blank')
ylabel('F statistic')
title(figTitle)
legend(delayNames)

% top voxels
figure
bar(fBlockByCondThreshedMean')
set(gca,'XTickLabel',stimCondNames)
xlabel('stim condition vs. blank')
ylabel('F statistic')
title(sprintf('%s (N=%d)', figTitle, threshIdx))
legend(delayNames)

% both
f1 = figure;
hold on
p1 = errorbar(repmat(hemoDelays',1,2), fBlockByCondMean, fBlockByCondStd);
p2 = errorbar(repmat(hemoDelays',1,2), fBlockByCondThreshedMean, fBlockByCondThreshedStd);
set(p1(1), 'Color', colors{1}, ...
    'DisplayName', sprintf('M all (N=%d)', nVox))
set(p1(2), 'Color', colors{2}, ...
    'DisplayName', sprintf('P all (N=%d)', nVox))
set(p2(1), 'Color', colors{1}, 'LineWidth', 2, ...
    'DisplayName', sprintf('M top (N=%d)', threshIdx))
set(p2(2), 'Color', colors{2}, 'LineWidth', 2, ...
    'DisplayName', sprintf('P top (N=%d)', threshIdx))
set(gca,'XTick',hemoDelays)
xlabel('delays')
ylabel('F statistic')
title(figTitle)
legend show

% make f-test scatter plots (m vs p)
f2 = figure('Position',[0 0 900 250]);
for iDelay = 1:nDelays
    subplot(1,nDelays,iDelay)
    plot(fBlockByCond(:,1,iDelay), fBlockByCond(:,2,iDelay),'k.')
    if iDelay==1
        xlabel([stimCondNames{1} ' F stat'])
        ylabel([stimCondNames{2} ' F stat'])
    elseif iDelay==nDelays
        xlabel(sprintf('Hemi %d', hemi))
    end
    title(delayNames{iDelay}) 
    xlim([0 max(fBlockByCondMax(:,1))])
    ylim([0 max(fBlockByCondMax(:,2))])
    axis square
end

if saveFigs
    print(f1, '-djpeg', fPlotFigSavePath)
    print(f2, '-djpeg', fScatterFigSavePath)
end


