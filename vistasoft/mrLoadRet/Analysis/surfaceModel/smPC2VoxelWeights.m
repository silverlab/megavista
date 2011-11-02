function model = smPC2VoxelWeights(model)
% Convert weights from PC space to voxel space for a surface map regression
% (if the regression was run in PC space)
%
% model = smPC2VoxelWeights(model)
%

if ~smGet(model, 'doPCA'), return; end

fprintf(1, '[%s]: Converting PC weights to voxel weights...\n', ...
    mfilename); drawnow;

% Get PCA fields
pcBetas = smGet(model, 'pcBetas'); 
coeff   = smGet(model, 'coeff');
score   = smGet(model, 'score');
% Convert the PC weights to voxel weights
reweight = inv(diag(std(score)));

% hacked method (this is invalid since it assumes that coeff' is the
% inverse of coeff, which it is not. on the other hand, it seems to work
% out.
voxelBetas = single( pcBetas *reweight* coeff');
% update: this actually checks out to be equivalent of single(coeff *
% reweight * pcBetas'), which is mathematically the right equation.
%voxelBetas = single(coeff * reweight * pcBetas');


% alternative method (algerbaicly correct?)
%voxelBetas = single(reweight * coeff' \ ( pcBetas'))';


% Save the voxel weights
model = smSet(model, 'voxelBetas', voxelBetas);

return