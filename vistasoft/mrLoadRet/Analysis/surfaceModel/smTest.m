function varExplained = smTest(model, scans, vw)
%   This function tests a given model
%   varexplained = smTest(model, scans, [vw])
%
% vw = view structure
% scans = scans which need to be used as test variables. pick the scans for
% which the model is not trained
% modelFile = saved .mat file where the trained model(using smmain) and all the
% associated data is stored.

%-------------------
% Variable check
%-------------------
if notDefined('vw'), vw = getCurView; end;
if notDefined('scans'),
    allscans  = 1:viewGet(vw, 'nScans');
    testscans = smGet(model, 'scans');
    scans     = setdiff(allscans, testscans);
end

if ischar(model)
    modelWrap = load(model);
    model = modelWrap.model;
end 

%-------------------
% Model check
%-------------------
if isempty(smGet(model, 'ROIX'))
    error('unable to get the predictors from the model');
end
if isempty(smGet(model, 'ROIYcoords'))
    error('unable to get the responsove variable coordinates');
end
if isempty(smGet(model, 'voxelBetas'))
    error('unable to get the weights');
end

%-------------------
% Get t-series
%-------------------

%get the stimulus or predictor ROI vars(test x_i's)
if (~strcmp(smGet(model, 'roiXname'), 'STIMULUS')) %model was predicted from ROI
    coords = smGet(model, 'ROIXcoords');
    if isempty(coords)
        error('unable to get the predictor ROI coordinates from the model');
    end
    fprintf(1, '[%s]: The predictor is %s. Getting TSeries\n', ...
        mfilename, smGet(model, 'roiXname'));
    X = voxelTSeries(vw, coords, scans);
else % model was predicted from stimulus
    fprintf(1, '[%s]: The predictor is Stimulus. Getting it\n', mfilename);
    X = smGetStimulus(vw, model, scans);
end

%get the test time series
yCoords = smGet(model, 'ROIYcoords');
Y = voxelTSeries(vw, yCoords, scans);

X = zscore(X);
Y = center(Y);


%-------------------
% Get betas
%-------------------
betas =  smGet(model, 'voxelBetas');

if (size(X, 2) ~= size(betas, 2))
    error('dimensions of weights and predictor/x_is must match');
end

%-------------------
% Test the model
%-------------------
pred         = X * betas';

%temp hack: to ensure that tseries are scaled similarly.
% pred = zscore(pred);
% Y = zscore(Y);

SSerr        = var(Y - pred);
SStot        = var(Y);
varExplained = 1 - SSerr./SStot; %#ok<NASGU>


% save the model
% modelDir = smGet(model, 'modelDirFull');
% fname = sprintf('testResults-%s.mat', datestr(clock, 30));
% save(fullfile(modelDir, fname), 'varExplained', 'scans');

%-------------------
% Done
%-------------------
fprintf(1,'Done\n');
return;


