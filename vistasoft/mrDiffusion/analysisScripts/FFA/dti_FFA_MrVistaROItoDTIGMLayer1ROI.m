function dti_FFA_MrVistaROItoDTIGMLayer1ROI(roiName, initials, subDir, fid)
%
% Usage: DY FILL THIS IN!
%
% This function will take an existing mrVista Volume ROI that has already
% been restricted to the gray matter and create a version of the ROI that
% includes only gray matter layer 1 voxels (Layer 1 = bordering WM) in
% mrDiffusion space. The original ROI is transformed to one that is only
% one layer thick. 
%
% This is useful when defining ROIs for use with conTrack. We want conTrack
% to track paths only to the GM/WM border, not deep into GM (where voxels
% are expected to be isotropic and non-informative). However, sometimes a
% functionally defined ROI in mrVista in a particular column of GM has
% several layers of active voxels, or skips layer 1 (e.g., has an "active"
% voxel in layer 3 only). So for all these cases, we just get the nearest
% layer 1 voxel.  
%
% Depends on vAnatomy.dat, ROis, dt6, meshes, etc to be named/structured/located
% correctly
% 
% Example: DY EDIT THIS!
% dti_FFA_MrVistaROItoDTIGMLayer1ROI('RH_RFFA_p3d', initials, subDir, fid);
%
% DY 2009/01/07
%


% Load the necessary files; we use the gray coordinates, wrinkled right
% hemisphere, and the specific ROI of interest.  ;
load(fullfile(subDir, 'fmri','Gray','coords.mat'));
load(fullfile(subDir, '3DAnatomy', 'Right', '3DMeshes',  [initials '_rh_wrinkled.mat']));
load(fullfile(subDir, 'fmri', 'Gray', 'ROIs', 'davie', [roiName '.mat']));
dt6file = fullfile(subDir,'dti30','dt6.mat');
saveDir = fullfile(subDir, 'dti30','ROIs','nrsa');
vAnatomy = fullfile(subDir,'3DAnatomy','vAnatomy.dat');
if (~isdir(saveDir))
    mkdir(saveDir);
end

% Distance threshold param (numVoxels away allowed)
% distThresh = 3mm. This usually works out to 3 voxels, but should be
% changed if the person's msh.mmPerVox is different (e.g., adult_RB has
% 0.8 X 0.8 X 0.8 mm voxels, so this number needs to be changed to four,
% which is 3.2mm
numVoxels_nv= 3; % Throw out mapped coords above this threshold (numVoxels) for layer 1 nodes to vertices

% Switch 1st and 2nd row (x/y coordinate order) in NODES to match x/y/z
% structure of ROI.coords.
remappedNodes = [nodes(2,:); nodes(1,:); nodes(3,:); nodes(4, :); nodes(5,:); nodes(6, :); nodes(7, :); nodes(8,:)];
remappedLayer1Nodes = remappedNodes(1:3,:);
remappedLayer1Nodes(1,nodes(6,:)~=1)=99999; % Make all the nodes that are not layer 1 very far away 

% Use nearpoints to find nearest layer 1 node, even if not in ROI
[roiLayer1NodeIndices,distSq] = nearpoints(double(ROI.coords),double(remappedLayer1Nodes));

% Need to map back into the original nodes space to use the
% mrmMapGrayToVertices function. 
layer1Nodes = [remappedLayer1Nodes(2, :); remappedLayer1Nodes(1, :); remappedLayer1Nodes(3, :)];
[g2vmap, distSq] = mrmMapGrayToVertices(layer1Nodes(:, roiLayer1NodeIndices), msh.vertices, msh.mmPerVox, numVoxels_nv*sqrt(3));
fprintf(fid,'\n\n%d layer 1 nodes thrown out because they were farther than %d voxels from corresponding vertices (should be 0)',...
    length(find(g2vmap == 0)), numVoxels_nv);
roiLayer1NodeIndices = removerows(roiLayer1NodeIndices', find(g2vmap==0))';
g2vmap = g2vmap(:, find(g2vmap ~= 0));
uniqueLayer1 = length(unique(roiLayer1NodeIndices', 'rows')');

gmlayer1Inds=unique(roiLayer1NodeIndices', 'rows'); 
gmlayer1Coords=remappedNodes(1:3,gmlayer1Inds);

% Create coordinates for both the wm ROI and the combined gray matter / white matter (gm/wm)
% ROI
dt6=dt6LoadAndCheckForXform(dt6file,vAnatomy,fid);
gmlayer1Coords=round(mrAnatXformCoords(dt6.xformVAnatToAcpc,gmlayer1Coords));

% Creates the new ROIs; a WM only ROI and a combination of the original ROI
% with its WM extension.
gmroi = dtiNewRoi([roiName '_gml1'], 'r', gmlayer1Coords);
dtiWriteRoi(gmroi,[fullfile(saveDir,gmroi.name) '.mat']);
return;


function dt6=dt6LoadAndCheckForXform(dt6file,vAnatomy,fid)

% Code lifted from dtiXformMrVistaVolROIs.m
% 11/05/2008 DY

dt6=load(dt6file);
% Check for dt6 XFORMVANATTOACPC field: this is a 4x4 matrix. If this field
% does not exist, check for vAnatomy and compute the xform.
if (~isfield(dt6,'xformVAnatToAcpc') || isempty(dt6.xformVAnatToAcpc))
    if (~exist('vAnatomy','var')||isempty(vAnatomy))
        fprintf(1,'\nFAILURE: no xform computed, and no vAnatomy found\n');
        fprintf(fid,'\nFAILURE: no xform computed, and no vAnatomy found\n');
        return 
    else % compute the xform
        [vAnatomyData,vAnatMm] = readVolAnat(vAnatomy); % Get VAnatomy
        % Get t1.nii.gz info
        subjDir=fileparts(fileparts(dt6file));
        ni = readFileNifti(fullfile(subjDir,dt6.files.t1));
        dtiAcpcXform = ni.qto_xyz;
        dtiT1 = double(ni.data);
        mmPerVox = ni.pixdim;
        % Compute xform
        [xformVAnatToAcpc] = dtiXformVanatCompute(dtiT1, dtiAcpcXform, vAnatomyData, vAnatMm);
        % Save xform to dt6 struct
        save(dt6file,'xformVAnatToAcpc','-APPEND');
        % Add xform field to current dt6 variable
        dt6.xformVAnatToAcpc=xformVAnatToAcpc;        
        fprintf(1,'\nSUCCESS: dt6 xform to vAnatomy computed\n');
        fprintf(fid,'\nSUCCESS: dt6 xform to vAnatomy computed\n');
    end
else
    fprintf(1,'\n mrVista XFORM found -- no need to compute new xform \n')
    fprintf(fid,'\n mrVista XFORM found -- no need to compute new xform \n')
end
return