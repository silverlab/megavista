function  model = smBasisMakePCs(model)
% Calculate principal components on regressor ROI tseries for surface model
% (see smMain.m)
%   model = smBasisMakePCs(model)

% Get the t-series
if smGet(model, 'useStimulus')
    tSeries = smGet(model, 'tSeries stimulus');
else
    tSeries = smGet(model, 'tSeries.X');
end
% Start the PCA
fprintf(1, '[%s]: Calculating PCs...\n', ...
    mfilename); drawnow;

% Calcualte the PCs
% Standardize(mean -> 0, var -> 1) the time series. this is a preprocessing
% step for princomp.
% is our matrix flipped? shouldnt we standardize every input vector, which
% for a stimulus -> roi prediction is the pixel values at one time point.
%tSeries = tSeries';
X = zscore(tSeries);
[coeff, score, latent] = princomp(X, 'econ');

% Check the number of PCs returned.
%   We need to do this because it is possible that we will get back fewer
%   components than we asked for. This will happen if the number of
%   observations (MR frames) is less than the number of PCs. In this case,
%   we reset the number of PCs in the model to avoid potential errors.
nBasisFunctions = smGet(model, 'nBasisFunctions');
if size(coeff, 2) < nBasisFunctions
    nBasisFunctions = size(coeff, 2);
    model = smSet(model, 'nBasisFunctions', nBasisFunctions);
end

% Store the results.
%   Note that we have the option to store the entire matrices, or to crop
%   them according to the number of PCs in the analysis. The smGet function
%   will crop them for us, so it might be worth saving the whole structure.
%   On the other hand, the structures are large. So we compromise by saving
%   the entire vector for 'latent', which is small, but only the cropped
%   parts of 'coeff' and 'score' since they are large.
model = smSet(model, 'basis functions',  coeff(:, 1:nBasisFunctions));
model = smSet(model, 'basis projection', score(:, 1:nBasisFunctions));
model = smSet(model, 'basis variance',   latent / sum(latent));

return