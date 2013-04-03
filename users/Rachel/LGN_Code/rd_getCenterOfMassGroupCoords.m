% rd_getCenterOfMassGroupCoords.m

%% Setup
hemi = 2;

varThresh = 0;
prop = .2;
voxelSelectionOption = 'varExp'; % all, varExp
betaCoefs = [0.5 -0.5];
mapName = 'betaM-P';

saveAnalysis = 1;

threshDescrip = sprintf('%0.03f', varThresh);
voxDescrip = ['varThresh' threshDescrip(3:end)];

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);
analysisSavePath = sprintf('%s_comVoxGroupCoords_%s_prop%d_%s_%s.mat', ...
    fileBase, mapName, round(prop*100), voxDescrip, datestr(now,'yyyymmdd'));

%% Load data
load(loadPath)

%% Set coordinates and associated values
coords = figData.coordsInplane';
nVox = size(coords,1);

betas = squeeze(figData.glm.betas(1,1:2,:))';
topoData = betas*betaCoefs';

%% Calculate centers for selected varThresh
%% Select voxels
switch voxelSelectionOption
    case 'all'
        voxelSelector = logical(ones(1,length(topoData)));
    case 'varExp'
        voxelSelector = figData.glm.varianceExplained > varThresh;
    otherwise
        error('voxelSelectionOption not found');
end

vals = topoData(voxelSelector);

%% Find voxels in each group
[centers voxsInGroup] = ...
    rd_findCentersOfMass(coords(voxelSelector,:), vals, prop, 'prop');

%% Organize coords and voxel classes into X and Y matrices
coords1 = coords(voxsInGroup(:,1),:);
coords2 = coords(voxsInGroup(:,2),:);

Y1 = ones(length(coords1),1);
Y2 = ones(length(coords2),1)*2;

voxCoords = [coords1; coords2]; % X in svm script
voxGroups = [Y1; Y2]; % Y in svm script

%% Save analysis
if saveAnalysis
    save(analysisSavePath,'hemi','betaCoefs','mapName','prop','varThresh',...
        'betas','topoData','centers','voxsInGroup',...
        'voxCoords','voxGroups','voxelSelectionOption')
end


