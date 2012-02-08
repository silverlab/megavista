% rd_mpMetric.m
%
% get a P-score and M-score for each voxel

%% Setup
hemi = 1;
scanDate = '20111025';
analysisDate = '20111025';

measureType = 'corAnalContrast';
plotFigs = 1;
saveAnalysis = 0;

%% File I/O
fileBase = sprintf('lgnROI%dAnalysis_%s', hemi, scanDate);
% analysisExtension = sprintf('_mpDistributionZ%s', analysisDate);
analysisExtension = sprintf('_mpDistributionCorAnalOrtho%s', analysisDate);
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);

% number metric files sequentially in order of creation. look up previous
% metric file to find its number and then save next file as next number.
metricFiles = dir([fileBase '_mpMetric*']);
if isempty(metricFiles)
    prevFile{3} = 0;
else
    prevFile = textscan(metricFiles(end).name, '%24s%9s%d%s');
end
metricExtension = sprintf('_mpMetric%04d', prevFile{3}+1);
savePath = sprintf('%s%s.mat', fileBase, metricExtension);

% write analysis info and results to a text file
% *** add code here ***

%% Load data
load(loadPath)

%% Get condition names
switch measureType
    case 'zScore'
        dataNames = condNames;
    case 'zContrast'
        dataNames = cell(length(contrasts.z),1);
        [dataNames{:}] = deal(contrasts.z.name);
    case 'zoContrast'
        dataNames = cell(length(contrasts.zo),1);
        [dataNames{:}] = deal(contrasts.zo.name);
    case 'corAnalContrast'
        fieldName = 'co'
        dataNames = cell(length(contrasts.(fieldName)),1);
        [dataNames{:}] = deal(contrasts.(fieldName).name);
    otherwise
        error('measure type (zScore, zContrast, etc.) not found')
end

%% Choose data
switch measureType
    case 'zScore'
        data = zScores;
    case 'zContrast'
        data = zContrasts;
    case 'zoContrast'
        data = zoContrasts;
    case 'corAnalContrast'
        data = contrastData.(fieldName);
    otherwise
        error('measure type (zScore, zContrast, etc.) not found')
end

%% Normalized data
nVox = size(data,1);
dataStd = std(data);
dataN = data./repmat(dataStd,nVox,1); % standardized data

%% Which data to use
vals = data;

%% M/P-score coefficients
% How much do we want to weight each contrast going into the M and P
% scores?
pCoefs = [1 1 1 1];
mCoefs = [1 1 1 1];

%% M/P-scores
%% 2 zScores: PHigh-MLow
pScores = -pCoefs(1).*vals(:,strcmp(dataNames,'MLow')) + ...
    pCoefs(2).*vals(:,strcmp(dataNames,'PHigh'));

%% 2 zScores: PHigh & PLow
pScores = -pCoefs(1).*vals(:,strcmp(dataNames,'PLow')) + ...
    pCoefs(2).*vals(:,strcmp(dataNames,'PHigh')) + ...
    (pCoefs(1).*vals(:,strcmp(dataNames,'PLow')) + ...
    pCoefs(2).*vals(:,strcmp(dataNames,'PHigh')))/2;

%% 2 zScores: MHigh & MLow
mScores = -abs(mCoefs(2).*vals(:,strcmp(dataNames,'MHigh')) - ...
    mCoefs(1).*vals(:,strcmp(dataNames,'MLow'))) + ...
    (mCoefs(1).*vals(:,strcmp(dataNames,'MLow')) + ...
    mCoefs(2).*vals(:,strcmp(dataNames,'MHigh')))/2;

%% 4 zScores
pScores = -pCoefs(1).*vals(:,strcmp(dataNames,'MLow')) - ...
    pCoefs(2).*vals(:,strcmp(dataNames,'MHigh')) - ...
    pCoefs(3).*vals(:,strcmp(dataNames,'PLow')) + ...
    pCoefs(4).*vals(:,strcmp(dataNames,'PHigh'));

%% 1 zContrast
pScores = pCoefs(1).*vals(:,strcmp(dataNames,'MHigh-MLow'));

%% 2 zContrasts
pScores = pCoefs(1).*vals(:,strcmp(dataNames,'PHigh-MHigh')) + ...
    pCoefs(2).*vals(:,strcmp(dataNames,'PHigh-PLow'));

mScores = -mCoefs(1).*vals(:,strcmp(dataNames,'PHigh-MHigh')) - ...
    mCoefs(2).*abs(vals(:,strcmp(dataNames,'MHigh-MLow')));

%% 4 zContrasts
pScores = pCoefs(1).*vals(:,strcmp(dataNames,'MHigh-MLow')) + ...
    pCoefs(2).*vals(:,strcmp(dataNames,'PHigh-PLow')) + ...
    pCoefs(3).*vals(:,strcmp(dataNames,'PLow-MLow')) + ...
    pCoefs(4).*vals(:,strcmp(dataNames,'PHigh-MHigh'));

mScores = -mCoefs(1).*abs(vals(:,strcmp(dataNames,'MHigh-MLow'))) - ...
    mCoefs(2).*abs(vals(:,strcmp(dataNames,'PHigh-PLow'))) - ...
    mCoefs(3).*vals(:,strcmp(dataNames,'PLow-MLow')) - ...
    mCoefs(4).*vals(:,strcmp(dataNames,'PHigh-MHigh'));

%% metric
pmScoreDiff = pScores-mScores;

%% Plot figures
if plotFigs
    
    %% boxplot
    figure
    boxplot([pScores mScores],'labels',{'P-score','M-score'})
    title(sprintf('Hemi %d', hemi))
    
    %% histogram
    figure
    hist(pmScoreDiff)
    title(sprintf('Hemi %d', hemi))

    %% imagesc
    figure
    imagesc([pScores mScores])
    xlabel('M/P-score')
    ylabel('voxel')
    title(sprintf('Hemi %d M/P-scores\n1 = P-score\n2 = M-score',hemi));
    colorbar
    
    %% scatter
    figure
    scatter(pScores,mScores)
    xlabel('P-score')
    ylabel('M-score')
    title(sprintf('Hemi %d', hemi))
    
end
    