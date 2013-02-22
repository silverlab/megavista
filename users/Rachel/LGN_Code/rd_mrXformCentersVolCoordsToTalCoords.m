function C = rd_mrXformCentersVolCoordsToTalCoords(hemi, mapName)
%
% Transforms center of mass cordinates from epi coords to volume coords, in
% order to reorient them to a canonical upright orientation.
%
% Note that you should start running this script in the ROIX0X directory,
% but it will soon cd up into (hopefully) the mrSession directory.
%
% Rachel Denison
% 2013 Feb 6

%% Setup
% hemi = 1;
% 
% mapName = 'betaM-P';

switch mapName
    case 'betaM-P'
        prop = 0.2;
    case 'betaM'
        prop = 0.2;
    case 'betaP'
        prop = 0.8;
    otherwise
        error ('mapName not recognized when setting prop and betaCoefs')
end

plotFigs = 1;
saveAnalysis = 0;

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = sprintf('centerOfMassVol_%s_prop%d', mapName, round(prop*100));
loadFile = dir(sprintf('%s_%s*',fileBase,analysisExtension));
analysisSavePath = sprintf('%s_centerOfMassTal_%s_prop%d_%s.mat', fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));

%% Load data
if numel(loadFile)~=1
    error('Too many or too few matching data files.')
else
    load(loadFile.name)
end

load ../../mrSESSION

%% Get xform info
% We want just the Talairach transform
skipTalFlag = 0;
skipSpatialNormFlag = 1;

talairach = loadTalairachXform(mrSESSION.subject,[],skipTalFlag,skipSpatialNormFlag);

%% Transform centers
% Transform centers coordinates (assumes coords are [3 x nvox])
% Note: Volume coords are [Ax Cor Sag], and Talairach coords are 
% [Sag Cor Ax] (right+ ant+ sup+)
[C.centers1Tal C.centers1TalNoScale] = rd_volToTalairach(C.centers1Vol, ...
    talairach.vol2Tal);
[C.centers2Tal C.centers2TalNoScale] = rd_volToTalairach(C.centers2Vol, ...
    talairach.vol2Tal);

%% Quick check of centers 1
if plotFigs
    figure('Position',[100 100 1000 400])
    subplot(1,3,1)
    scatter(C.centers1Vol(:,3),C.centers1Tal(:,1))
    xlabel('vol left <---> right')
    ylabel('tal left <---> right')
    subplot(1,3,2)
    scatter(C.centers1Vol(:,2),C.centers1Tal(:,2))
    xlabel('vol ant <---> post')
    ylabel('tal post <---> ant')
    subplot(1,3,3)
    scatter(C.centers1Vol(:,1),C.centers1Tal(:,3))
    xlabel('vol sup <---> inf')
    ylabel('tal inf <---> sup')
end

%% Save data
if saveAnalysis
    save(analysisSavePath,'C')
end

