function vw = smPointROI(model, vox, vw)
% create a point-ROI for a regressed voxel in order to display it on the mesh
%
% vw = smPointROI(model, voxelNum, [vw])
%
%   model: a surface-referenced pRF model (see smMain)
%   vox:   either be a volume coordinate (3x1) or an integer index into the
%           ROI's coordinate
%   vw:    mrVista view struct (default = curView)

%----------------------------------------
% var check
if notDefined('model'),     error('[%s]: Need a model', mfilename); end
if notDefined('vox'),  error('[%s]: Need to specify a voxel', mfilename); end
if notDefined('vw'),        vw = getCurView; end
%----------------------------------------

% if the input voxel is a 3x1 coordinate
if length(vox) == 3, vox = smGet(model, 'roiYindex', vox); end
pt = smGet(model, 'roiYcoords', vox);

% name the point ROI
roiYname = smGet(model, 'roiYname');
pointroi = sprintf('POINT %s_%d', roiYname, vox);

% load it into the view
vw       = newROI(vw, pointroi,1,'k',pt);

vw =  refreshScreen(vw);

return