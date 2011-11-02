function [gmroi,wmroi]=dti_FFA_MrVistaROItoDTIGMWMLayerROI(roiName, initials, theDirs, fid, wml1flag, hemiFlag)
%
% Usage: 
% dti_FFA_MrVistaROItoDTIGMLayer1ROI(roiName, initials, theDirs,
% fid, [wml1flag=false], [hemiFlag='r'])
%
% INPUTS:
% roiName = ROI file name as string without .mat, EXAMPLE: roiName='RH1';
%           the file should be located in theDirs.mrvDir
% initials = 'dy' -- needed for finding the mesh file
% theDirs.subDir= 'full/path/to/subjectDir' ('fmri' and 'dti30' at top level)
% theDirs.mrvDir= 'full/path/to/mrVista/roiDir' (mrVista ROI path)
% theDirs.saveDir= 'full/path/to/mrDiffusion/roiDir' (mrDiffusion ROI path)
% fid = can be set to 1 if you do not want to write status to a log file
% wml1flag = will also create a WML1ROI; default is false
% hemiFlag = set to 'r' or 'l' in order to load the correct mesh, which is
% always the uninflated wrinkled one. Default is 'r'. 
%
% OUTPUTS:
% gmroi/wmroi: struct variables (similar to output from dtiReadROI)
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
% History:
% 2009/01/07: DY wrote dti_FFA_MrVistaROItoGMLayer1ROI
% 2009/11/09: DY added capacity to return WML1 as well with 'wml1flag';
% This code is based on:
% /biac2/kgs/projects/Kids/dti/inactive_projects/sfn/roiGrowIntoWhiteMatter
% LoadNormsFromVertices_121108.m
% 2010/01/11: DY added optional hemiFlag in order to handle ROIs from
% either LH or RH


% Load the necessary files; we use the gray coordinates, wrinkled mesh
% hemisphere, and the specific ROI of interest.  ;
load(fullfile(theDirs.subDir, 'fmri','Gray','coords.mat'));
load(fullfile(theDirs.mrvDir, [roiName '.mat']));
dt6file = fullfile(theDirs.subDir,'dti30','dt6.mat');
vAnatomy = fullfile(theDirs.subDir,'3DAnatomy','vAnatomy.dat');
if (~isdir(theDirs.saveDir))
    mkdir(theDirs.saveDir);
end

if notDefined('hemiFlag'), hemiFlag='r'; end
switch hemiFlag
    case 'r'
        load(fullfile(theDirs.subDir, '3DAnatomy', 'Right', '3DMeshes',  [initials '_rh_wrinkled.mat']));
    case 'l'
        load(fullfile(theDirs.subDir, '3DAnatomy', 'Left', '3DMeshes',  [initials '_lh_wrinkled.mat']));
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

% Get coordinates for the GML1 ROI in mrDiffusion
% space
dt6=dt6LoadAndCheckForXform(dt6file,vAnatomy,fid);
gmlayer1Coords=round(mrAnatXformCoords(dt6.xformVAnatToAcpc,gmlayer1Coords));

% If wml1flag is true, also create and save a WML1 ROI.
% Makes a set of coordinates that is each ROI layer1 vertex coordinate + the normal
% vector and each ROI layer1 vertex coordinate - the normal vector; saves
% both sets of data in one matrix for later processing.
%
% NOTES: because we're taking the floor and the ceiling of every
% wm coordinate we get, the end result tends to grow in about two layers
% rather than one. We also need to fill in the holes created by this method
% on non-line ROIs. See the original code for more info:  
% /biac2/kgs/projects/Kids/dti/inactive_projects/sfn/roiGrowIntoWhiteMatter
% LoadNormsFromVertices_121108.m

if notDefined('wml1flag'), wml1flag=false; end % if input argument not passed, set to false
if wml1flag
    roiWhiteLayer1Coords = []; % initialize
    numLayers = 1; % unncessary if the for loop is functional
    roiWhiteLayer1Coords = [roiWhiteLayer1Coords (remappedLayer1Nodes(:, roiLayer1NodeIndices) + numLayers * msh.normals(:,g2vmap)) (remappedLayer1Nodes(:, roiLayer1NodeIndices) - numLayers * msh.normals(:,g2vmap))];
    
    % Takes every combination of floors and ceilings of the resulting
    % coordinates to get the integers corresponding to the roiWhiteLayer1Coords
    expandedroiWhiteLayer1Coords = [];
    expandedroiWhiteLayer1Coords = [[floor(roiWhiteLayer1Coords(1, :)') floor(roiWhiteLayer1Coords(2, :)') floor(roiWhiteLayer1Coords(3, :)')]' expandedroiWhiteLayer1Coords];
    expandedroiWhiteLayer1Coords = [[floor(roiWhiteLayer1Coords(1, :)') floor(roiWhiteLayer1Coords(2, :)') ceil(roiWhiteLayer1Coords(3, :)')]' expandedroiWhiteLayer1Coords];
    expandedroiWhiteLayer1Coords = [[floor(roiWhiteLayer1Coords(1, :)') ceil(roiWhiteLayer1Coords(2, :)') floor(roiWhiteLayer1Coords(3, :)')]' expandedroiWhiteLayer1Coords];
    expandedroiWhiteLayer1Coords = [[ceil(roiWhiteLayer1Coords(1, :)') floor(roiWhiteLayer1Coords(2, :)') floor(roiWhiteLayer1Coords(3, :)')]' expandedroiWhiteLayer1Coords];
    expandedroiWhiteLayer1Coords = [[floor(roiWhiteLayer1Coords(1, :)') ceil(roiWhiteLayer1Coords(2, :)') ceil(roiWhiteLayer1Coords(3, :)')]' expandedroiWhiteLayer1Coords];
    expandedroiWhiteLayer1Coords = [[ceil(roiWhiteLayer1Coords(1, :)') ceil(roiWhiteLayer1Coords(2, :)') floor(roiWhiteLayer1Coords(3, :)')]' expandedroiWhiteLayer1Coords];
    expandedroiWhiteLayer1Coords = [[ceil(roiWhiteLayer1Coords(1, :)') floor(roiWhiteLayer1Coords(2, :)') ceil(roiWhiteLayer1Coords(3, :)')]' expandedroiWhiteLayer1Coords];
    expandedroiWhiteLayer1Coords = [[ceil(roiWhiteLayer1Coords(1, :)') ceil(roiWhiteLayer1Coords(2, :)') ceil(roiWhiteLayer1Coords(3, :)')]' expandedroiWhiteLayer1Coords];

    % Removes the duplicates from the dataset so that a given coordinate will
    % appear only once in the expanded dataset (there are a ton of duplicates,
    % but this isn't worrisome because we'd expect significant duplication...)
    expandedroiWhiteLayer1Coords = unique(expandedroiWhiteLayer1Coords', 'rows')';

    % Intersects the roiWhiteLayer1Coords with the remappedNodes, which
    % represent all gray matter nodes. This removes all nodes in the
    % roiWhiteLayer1Coords that are in the gray matter (because we add and
    % subtract the normal, we don't know convexity of anatomy)
    roiWhiteLayer1Coords = expandedroiWhiteLayer1Coords;
    roiWhiteLayer1Coords = setdiff(roiWhiteLayer1Coords', remappedNodes(1:3,:)', 'rows')';

    % Get coordinates for the WML1 ROI in mrDiffusion space
    wmcoords=round(mrAnatXformCoords(dt6.xformVAnatToAcpc, roiWhiteLayer1Coords));

    % Say what happened
    fprintf(fid, '\n\n%d unique gray matter layer 1 nodes \n\n%d unique white matter voxels.', uniqueLayer1,length(roiWhiteLayer1Coords));

    % Creates the new WML1 ROI
    wmroi = dtiNewRoi([roiName '_wml' num2str(numLayers)], 'g', wmcoords);
    dtiWriteRoi(wmroi,[fullfile(theDirs.saveDir,wmroi.name) '.mat']);

end

% Creates the new GML1 ROI
gmroi = dtiNewRoi([roiName '_gml1'], 'r', gmlayer1Coords);
dtiWriteRoi(gmroi,[fullfile(theDirs.saveDir,gmroi.name) '.mat']);
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