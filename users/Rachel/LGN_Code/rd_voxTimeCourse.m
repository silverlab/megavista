% rd_voxTimeCourse.m
%
% see tc_init.m

%% setup
hemi = 2;
voxelSelectionOption = 'varExp';
varThresh = 0;
betaThresh = 0;

%% file I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);

%% load data
load(loadPath)

%% get data info
voxs = 1:size(figData.tSeries,2);
nConds = numel(figData.trials.condNums);
condNames = figData.trials.condNames;
params = figData.params;

% reset any params
params.normBsl = 1;

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

%% plot mean tcs for all voxels
for iCond = 1:nConds
    figure
%     plot(voxtc.timeWindow, squeeze(voxMeanTcs(:,iCond,:)));
    plot(squeeze(voxMeanTcs(:,iCond,:)));
    title(sprintf('%s, %s', condNames{iCond}, voxDescrip));
    
    hold on
%     plot(voxtc.timeWindow, mean(squeeze(voxMeanTcs(:,iCond,:)),2),...
%         'k','LineWidth',2)
    plot(mean(squeeze(voxMeanTcs(:,iCond,:)),2),...
        'k','LineWidth',2)
end

%% plot difference tcs
for iCond = 2:nConds
    figure
    condDiff = squeeze(voxMeanTcs(:,iCond,:)-voxMeanTcs(:,1,:));
%     plot(voxtc.timeWindow, condDiff);
    plot(condDiff);
    title(sprintf('%s - %s, %s', ...
        condNames{iCond}, condNames{1}, voxDescrip));
    
    hold on
%     plot(voxtc.timeWindow, mean(squeeze(voxMeanTcs(:,iCond,:)-voxMeanTcs(:,1,:)),2),...
%         'k','LineWidth',2)
    plot(mean(squeeze(voxMeanTcs(:,iCond,:)-voxMeanTcs(:,1,:)),2),...
        'k','LineWidth',2)
end