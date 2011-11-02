function model = smXform2VoxelWeights(model)
% Convert weights from transform space to pixel/voxel space for a surface map regression
%
% model = smXform2VoxelWeights(model)
%

fprintf(1, '[%s]: Converting transform weights to voxel weights...\n', ...
    mfilename); drawnow;

% Get xform fields
xformBetas       = smGet(model, 'xformBetas'); 
xformFunctions   = smGet(model, 'xform functions');
xformProjection  = smGet(model, 'xform projection');
reweigt          = false;

% Convert the transform weights to voxel weights
%   *If* we standardized our regressors before regression, then we have to
%   unstandardize them now by rewighting them. But did we??? Should we???
%   If we did, how do we know???
if reweigt, 
    reweight = inv(diag(std(xformProjection)));
    voxelBetas = single(xformFunctions * reweight * xformBetas);
else
    voxelBetas = single(xformFunctions * xformBetas);
end

% Save the voxel weights
model = smSet(model, 'voxelBetas', voxelBetas);

return