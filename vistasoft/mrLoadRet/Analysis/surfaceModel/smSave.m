function smSave(model)
% save a surface referred pRF model (see smMain)
%   smSave(model)
%

fname = smGet(model, 'modelFileFull');

save(fname, 'model');

% save a readme file if one doesn't exist
modelDir = smGet(model, 'modelDirFull');
if ~exist(fullfile(modelDir, 'ModelInfo.m'), 'file')
    fid = fopen(fullfile(modelDir, 'ModelInfo.m'), 'w');
    smModelInfo(model, fid)
    fclose(fid);
end
return
