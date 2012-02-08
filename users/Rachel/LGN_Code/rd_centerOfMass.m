% rd_centerOfMass.m

%% Setup
hemi = 2;
scanDate = '20110920';
mpDistributionDate = '20110920';
mpMetricNumber = '0001';

mpThresh = 0;

plotFigs = 1;
saveAnalysis = 0;

%% File I/O
fileBase = sprintf('lgnROI%dAnalysis_%s', hemi, scanDate);
distExtension = sprintf('_mpDistributionZ%s', mpDistributionDate);
distPath = sprintf('%s%s.mat', fileBase, analysisExtension);
metricExtension = sprintf('_mpMetric%s', mpMetricNumber);
metricPath = sprintf('%s%s.mat', fileBase, metricExtension);

%% Load data
load(distPath)
load(metricPath)

%% Set coordinates and associated values
coords = data(1).lgnROICoords';
vals = pmScoreDiff;
nVox = size(coords,1);

%% Analysis
[centers voxsInGroup] = rd_findCentersOfMass(coords, vals, mpThresh);
