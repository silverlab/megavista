function vw  = smMakeParameterMap(model, voxelNum, vw)
% vw = smMakeParameterMap(model, voxelNum, [vw]);

%----------------------------------------
% var check
if notDefined('model'), error('[%s]: Need a model', mfilename); end
if notDefined('vw'),    vw = getCurView; end
if notDefined('voxelNum'), error('[%s]: Need to specify a voxel', mfilename); end
%----------------------------------------

% get the gray node indices of the predictor ROI
grayCoords = viewGet(vw, 'coords');
roiXcoords = smGet(model, 'roiXcoords');
[foo foo roiXindices] = intersectCols(roiXcoords, grayCoords);

% set map for first scan to zeros, and delete maps for other scans
n = size(vw.coords,2);
map = cell(1);
map{1} = zeros(1,n);

% put the weights into the map
% the supposedly correct values:
voxelBetas = smGet(model, 'voxelBetas', voxelNum);
% the method that produces better looking maps:
% betas  = smGet(model, 'pcBetas', voxelNum);
% latent = smGet(model, 'latent');
% coeffs = smGet(model, 'coeff');            
% reweighted = latent .* betas';
% voxelBetas = coeffs * reweighted;

map{1}(roiXindices) = voxelBetas;

%name the map
mapName = [smGet(model, 'roiYname') num2str(voxelNum)];

% load it into the view
vw =  setParameterMap(vw,map,mapName, 'Beta values');
vw =  setDisplayMode(vw,'map');

% clip the map to the min and max values 
mapwin =  [-max(abs(voxelBetas)) max(abs(voxelBetas))];
vw =  viewSet(vw,'mapwin', mapwin);
vw =  viewSet(vw,'mapclipmode', mapwin);

%vw.ui.mapMode=setColormap(vw.ui.mapMode, 'jetCmap');
    
vw =  refreshScreen(vw);

return


    