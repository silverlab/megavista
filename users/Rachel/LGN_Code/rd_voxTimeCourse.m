% rd_voxTimeCourse.m
%
% see tc_init.m

%% setup
hemi = 2;
voxelSelectionOption = 'varExp';
varThresh = 0;
betaThresh = 0;

saveData = 0;
saveFigs = 0;

%% file I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);
analysisSavePath = sprintf('%s_timeCourses_%s.mat', fileBase, datestr(now,'yyyymmdd'));
plotSavePath = sprintf('figures/%sPlot_timeCourses', fileBase);

%% load data
load(loadPath)

%% get data info
voxs = 1:size(figData.tSeries,2);
nConds = numel(figData.trials.condNums);
condNames = figData.trials.condNames;
params = figData.params;

% reset any params
params.normBsl = 1;

% calculate frame window (in TRs) used by er_chopTSeries2 (lines 165-171)
timeWindow = params.timeWindow;
TR = figData.trials.TR;
t1 = min(timeWindow);  t2 = max(timeWindow);
f1 = fix(t1 / TR);  f2 = fix(t2 / TR);
frameWindow = f1:f2;

%% voxel selection
switch voxelSelectionOption
    case 'varExp'
        voxelSelector = figData.glm.varianceExplained > varThresh;
    case 'beta'
        voxelSelector = squeeze(figData.glm.betas(:,2,:) > betaThresh);
    case 'voxGroup'
        voxelSelector = voxsInGroup(:,1);
    otherwise
        error('voxelSelectionOption not found')
end

voxDescrip = sprintf('varExp > %.02f', varThresh);

%% choose voxels
voxs = voxs(voxelSelector);
nVox = numel(voxs);

%% get vox mean tcs for all voxels
voxMeanTcs = [];
for iVox = 1:nVox 
    voxIdx = voxs(iVox);
    voxtc = er_chopTSeries2(figData.tSeries(:,voxIdx)', ...
        figData.trials, params);
    
    voxMeanTcs(:,:,iVox) = voxtc.meanTcs;
end
voxMeanTcs_dimHeaders = {'TR','cond','vox'};

%% plot mean tcs for all voxels
for iCond = 1:nConds
    fig1(iCond) = figure;
    plot(frameWindow*TR, squeeze(voxMeanTcs(:,iCond,:)));
    xlabel('time (s)')
    ylabel('BOLD amplitude')
    title(sprintf('Hemi %d, %s, %s', hemi, condNames{iCond}, voxDescrip));
    
    hold on
    plot(frameWindow*TR, mean(squeeze(voxMeanTcs(:,iCond,:)),2),...
        'k','LineWidth',2)
    plot(frameWindow*TR, zeros(size(frameWindow)),'--k','LineWidth',1)
end

%% plot difference tcs
for iCond = 2:nConds
    fig2(iCond) = figure;
    condDiff = squeeze(voxMeanTcs(:,iCond,:)-voxMeanTcs(:,1,:));
    plot(frameWindow*TR, condDiff);
    xlabel('time (s)')
    ylabel('BOLD amplitude')
    title(sprintf('Hemi %d, %s - %s, %s', ...
        hemi, condNames{iCond}, condNames{1}, voxDescrip));
    
    hold on
    plot(frameWindow*TR, mean(squeeze(voxMeanTcs(:,iCond,:)-voxMeanTcs(:,1,:)),2),...
        'k','LineWidth',2)
    plot(frameWindow*TR, zeros(size(frameWindow)),'--k','LineWidth',1)
end

%% save data
if saveData
    save(analysisSavePath, 'hemi', 'voxelSelectionOption', 'varThresh', 'betaThresh', ...
        'frameWindow', 'TR', 'voxMeanTcs', 'voxMeanTcs_dimHeaders');
end

%% save figs
if saveFigs
    for iF = 1:numel(fig1)
        print(fig1(iF),'-djpeg', sprintf('%s_%s_%s', plotSavePath, condNames{iF}, datestr(now,'yyyymmdd')));
    end
    
    for iF = find(fig2)
        print(fig2(iF),'-djpeg', sprintf('%s_%s-%s_%s', plotSavePath, condNames{iF}, condNames{1}, datestr(now,'yyyymmdd')));
    end
end

