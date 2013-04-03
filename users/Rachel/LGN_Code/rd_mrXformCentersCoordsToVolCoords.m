function rd_mrXformCentersCoordsToVolCoords(hemi, mapName)
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
saveAnalysis = 1;

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = sprintf('centerOfMass_%s_prop%d', mapName, round(prop*100));
loadFile = dir(sprintf('%s_%s*',fileBase,analysisExtension));
analysisSavePath = sprintf('%s_centerOfMassVol_%s_prop%d_%s.mat', fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));

%% Load data
if numel(loadFile)~=1
    error('Too many or too few matching data files.')
else
    load(loadFile.name)
end

load ../../mrSESSION

%% Get xform info
% Get voxel sizes
epiVoxSize = mrSESSION.functionals.voxelSize;
ipVoxSize = mrSESSION.inplanes.voxelSize;
% volVoxSize = readVolAnatHeader(vANATOMYPATH);
volVoxSize = [1 1 1];

% get upsample factor
% n = upSampleFactor(INPLANE{1},1);
n = epiVoxSize./ipVoxSize;

% Get xform
xform = mrSESSION.alignment;

%% Transform centers
% Upsample centers to convert them from epi to inplane coords
centers1Ip = bsxfun(@times,C.centers1,n);
centers2Ip = bsxfun(@times,C.centers2,n);

% Transform centers coordinates (assumes coords are [3 x nvox])
% Note: Volume coords are [Ax Cor Sag], whereas Inplane coords are 
% [Sag Cor Ax]
C.centers1Vol = rd_xformCoordsNoRounding(centers1Ip', xform)';
C.centers2Vol = rd_xformCoordsNoRounding(centers2Ip', xform)';

% For comparison: The output c1temp is offset from C.centers1Vol by a 
% specific, constant value in each dimension, the same offset values for 
% centers 1 and 2. I think this offset is added in order to do supersampling
% for partial voluming, so it is not what we want. Either way, these should 
% give the same results for distances between centers.
[c1roi c1temp] = xformROIcoords(centers1Ip', xform, ipVoxSize, volVoxSize);
[c2roi c2temp] = xformROIcoords(centers2Ip', xform, ipVoxSize, volVoxSize);
c1temp = c1temp(1:3,:)';
c2temp = c2temp(1:3,:)';

%% Quick check of centers 1
if plotFigs
    figure('Position',[100 100 1000 400])
    subplot(1,3,1)
    scatter(C.centers1(:,1),C.centers1Vol(:,3))
    xlabel('ip left <---> right')
    ylabel('vol left <---> right')
    subplot(1,3,2)
    scatter(C.centers1(:,2),C.centers1Vol(:,2))
    xlabel('ip post <---> ant')
    ylabel('vol ant <---> post')
    subplot(1,3,3)
    scatter(C.centers1(:,3),C.centers1Vol(:,1))
    xlabel('ip inf <---> sup')
    ylabel('vol sup <---> inf')
end

%% Save data
if saveAnalysis
    save(analysisSavePath,'C')
end

