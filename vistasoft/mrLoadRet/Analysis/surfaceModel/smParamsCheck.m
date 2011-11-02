function [model vw] = smParamsCheck(model, vw)
% Check whether we have all necessary fields set for a surface
% model of BOLD activity (see smMain.m). If necessary fields are missing,
% set defaults. Then we can proceed safely. (hopefully)
% 
% [model vw] = smParamsCheck(model, vw)
%
% necessary fields:
%   roiX, roiY, dtNum, dtName, scans, regressionMethod, doPCA, nPCs,
%   modelFile, modelDir
% 

% rightMeshFile = '/biac2/wandell/data/MachineLearning/HH080213/rightMeshInflated.mat';
% leftMeshFile = '/biac2/wandell/data/MachineLearning/HH080213/leftMeshInflated.mat';
fprintf(1, '[%s]: Checking parameters...', mfilename);


% Check to see if we are regressing on a stimulus or an ROI
useStimulus = smGet(model, 'useStimulus');

if useStimulus 
    % if we are regressing on a stimulus make sure one exists
    val = smGet(model, 'stimulus');
    if isempty(val)
        error('[%s]: No stimulus to regress on. Aborting...', mfilename);
    end

else
    % if we are regressing on an ROI make sure it exists
    val = smGet(model, 'roiX');
    if isempty(val)
        error('[%s]: No regressor ROI. Aborting...', mfilename);
    end
end

val = smGet(model, 'roiY');
if isempty(val)
    error('[%s]: No regressed ROI. Aborting...', mfilename);
end

% we don't need a mesh to solve the model!!
% val = smGet(model, 'roixmesh');
% if isempty(val)
%     roiXname = smGet(model, 'roixname');
%     if (~strcmp(roiXname, 'STIMULUS'))
%         switch lower(roiXname)
%             case{'rv1','rv2'}
%                 model = smSet(model, 'roixmesh', rightMeshFile);
%             case{'lv1','lv2'}
%                 model = smSet(model, 'roixmesh', leftMeshFile);
%         end
%     end
% end
% 
% val = smGet(model, 'roiymesh');
% if isempty(val)
%     roiYname = smGet(model, 'roiyname');
%     if (~strcmp(roiYname, 'STIMULUS'))
%         switch lower(roiYname)
%             case{'rv1','rv2'}
%                 model = smSet(model, 'roiymesh', rightMeshFile);
%             case{'lv1','lv2'}
%                 model = smSet(model, 'roiymesh', leftMeshFile);
%         end
%     end
% end
% 
% val = smGet(model, 'meshview');
% if isempty(val)
%     roiXname = smGet(model, 'roixname');
%     if (~strcmp(roiXname, 'STIMULUS'))
%         if (strcmp(roiXname, 'LV1'))
%             model = smSet(model, 'meshview', 'LV1LV2');
%         end
%         if (strcmp(roiXname, 'RV1'))
%             model = smSet(model, 'meshview', 'RV1RV2');
%         end
%     end
% end

% dataType
val = smGet(model, 'dtNum');
if isempty(val)
    num   = viewGet(vw, 'curDataType');
    name  = viewGet(vw, 'dataType'); 
    model = smSet(model, 'dtNum', num);
    model = smSet(model, 'dtName', name);    
end
val = smGet(model, 'dtNum');
vw  = viewSet(vw, 'curdt', val);

% scans
val = smGet(model, 'scans');
if isempty(val)
    scans = 1:viewGet(vw, 'nscans'); 
    model = smSet(model, 'scans', scans);
end

% regression method
val = smGet(model, 'regressionMethod');
if isempty(val)
    model = smSet(model, 'regressionMethod', 'standard');
end

% basis set (gaussian basis set, PCs, raw data, etc.)
val = smGet(model, 'basisType');
if isempty(val)
    model = smSet(model,'basisType', 'original data');
end

val = smGet(model, 'nBasisFunctions');
if isempty(val)
    nPredictors = smGet(model, 'nPredictors');
    model = smSet(model,'nBasisFunctions', nPredictors);
end

val = smGet(model, 'modelFile');
if isempty(val)
    x = smGet(model, 'roiXname');
    y = smGet(model, 'roiYname');
    
    fname = sprintf('surf-model-%sto%s-%s', x, y, datestr(clock, 30));
    model = smSet(model,'modelFile', fname);
end

val = smGet(model, 'modelDir');
if isempty(val)
    fname = smGet(model, 'modelFile');
    dirname = [fname 'Dir'];
    model = smSet(model,'modelDir', dirname);
end

val = smGet(model, 'modelDirFull');
if ~isdir(val),
    mkdir(val);
end

val = smGet(model, 'projectdir');
if isempty(val)
    projectdir = viewGet(vw, 'homedir');
    model = smSet(model,'projectDir', projectdir);
end

fprintf(1, 'OK.\n');


return