% dti_OTS_createVinckierRois
%
% This script will take a set of seed points and from them grow an ROI for
% use with conTrack. 
% Coordinates taken from Vinckier et. al. (Neuron, 2007)
%
%
% History:
% 08.26.09 - LMP wrote the thing
%

% Search for this function 'mrAnatComputeSpmSpatialNorm' in analysis scripts for example usage. 
% use the add sphere function post to prevent non-sphere shape.

%%

baseDir = '/biac3/wandell4/data/reading_longitude/dti_adults/';
subDir = fullfile(baseDir,'aab050307','dti06');
roiDir = fullfile(subDir,'ROIs');

dt = dtiLoadDt6(fullfile(subDir,'dt6.mat'));
ni = readFileNifti(fullfile(subDir,'MNI_coordLUT.nii.gz'));

fusRoiName = {'VinckierOTS1','VinckierOTS2','VinckierOTS3','VinckierOTS4','VinckierOTS5','VinckierOTS6'};  
fusAllRoiName = {'VinckierOTS1-6'};
brocaRoiName = {'VinckierBrocaLateral','VinckierBrocaIntermediate','VinckierBrocaMesial'};
brocaAllRoiName = {'VinckierBrocaAll'};

fusRoiInd = {[-50 -40 -18],[-50 -48 -16],[-48 -56 -16],[-46 -64 -14],[-36 -80 -12],[-18 -96 -10]}; % Anterior to posterior
brocaRoiInd = {[-46 22 0],[-40 26 0],[-30 26 0]}; % Lateral, Intermediate, Mesial

for ii = 1:numel(fusRoiInd)
    radius = 4;
    center = fusRoiInd{ii};
    coords = dtiBuildSphereCoords(center, radius);
    
    roi = dtiNewRoi([fusRoiName{ii}],'y',coords);
    dtiWriteRoi(roi,fullfile(roiDir,roi.name),[],'MNI',ni.qto_xyz); % PROBLEM here may be with the xform. dt.xformToAcpc
end




