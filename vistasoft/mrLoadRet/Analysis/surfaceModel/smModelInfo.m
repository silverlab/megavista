function smModelInfo(model, fid)
% Display a summary of analysis parareters for a brain referred pRF model
%   (see smMain.m)
%
% smModelInfo(model)
%
% JW 2/2009
if notDefined('fid'), fid = 1; end

fprintf(fid, '****************************************\n');
fprintf(fid, 'Model: ''%s''\n', smGet(model, 'modelname'));
fprintf(fid, '\tProject dir: \t%s\n',   smGet(model, 'projectDir'));
fprintf(fid, '\tData TYPE: \t%s\n',     smGet(model, 'dtName'));
fprintf(fid, '\tscans:     \t%s\n',         num2str(smGet(model, 'scans')));
fprintf(fid, '\tPredictor ROI: \t%s\n',         smGet(model, 'roiXname'));
fprintf(fid, '\tResult ROI: \t%s\n',         smGet(model, 'roiYname'));

fprintf(fid, 'The regression type was ''%s''. ', smGet(model, 'regressionType'));
fprintf(fid, '%d PCs were used.\n', smGet(model, 'doPCA') * smGet(model, 'nPCs'));
fprintf(fid, '****************************************\n');

return