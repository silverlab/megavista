% rd_quickPlotTopoHist.m

hemi = 1;
betaWeights = [.5 -.5];
varThresh = 0

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);

%% Load data
load(loadPath)

%% Choose data to show here
betas = squeeze(figData.glm.betas(1,1:2,:))';
topoData = betas*betaWeights';

%% Any voxel selection?
voxelSelector = figData.glm.varianceExplained > varThresh;

%% Histogram of the values being mapped
f0 = figure;
hist(topoData(voxelSelector))
ylabel('number of voxels')