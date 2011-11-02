function model = smRegress(model)
%   model = smRegress(model)
%

%--------------------------------------------------------------
% Define the regressors
%--------------------------------------------------------------

% X: predictor in xform space (either the stimulus or an ROI)
X = smGet(model, 'score');

% Y: t-series to predict
Y = smGet(model, 'tSeriesY');

%--------------------------------------------------------------
% Do the regression
%--------------------------------------------------------------
regressionMethod = smGet(model, 'regressionMethod');
fprintf(1, '[%s]: Calculating regression using method: %s\n', ...
    mfilename, regressionMethod); drawnow;

nTimePoints = size(X,1);
nPredictors = size(X,2);
nVoxels     = size(Y,2);
betas       = zeros(nPredictors, nVoxels);
rmsErrors   = zeros(nVoxels, 1);

switch lower(regressionMethod)
    case {'lars', 'lasso'}
        % Do we want to zscore X??? If so, we need to record this fact so
        % we can take this into account when transforming out regression
        % solution from xform space back to pixel / voxel space. This is
        % important.
        X = zscore(X);
        Y = zscore(Y);
    case 'standard'
        % Do we want to zscore X??? If so, we need to record this fact so
        % we can take this into account when transforming out regression
        % solution from xform space back to pixel / voxel space. This is
        % important.
        X = zscore(X);
        Y = center(Y);
    otherwise
        X = zscore(X);
        Y = center(Y);
end

counter = round((1:10)/10 * nVoxels);

for vox = 1:nVoxels
    if any(vox  == counter), fprintf('.'); drawnow; end

    y = Y(1:nTimePoints, vox);

    switch lower(regressionMethod)
        case {'lars', 'lasso'}
            y = zscore(y);
            [b r] = myLasso(X, y);
        case {'gpsr'} 
            % Gradient Projection for Sparse Reconstruction (Figueredo, Nowak, wright)
            y = zscore(y);
            tau = 5;
            b = GPSR_BB(y, X, tau, 'verbose', true);
        case 'standard'
            [b, foo, foo, foo,  stats] = regress(y, [X ones(size(X,1), 1)]);
            b = b(1:end-1);
            r = stats(1);
        otherwise
            warning('[%s]: Unknown regression type. Using standard regression', mfilename);
            [b, foo, foo, foo,  stats] = regress(y, [X ones(size(y))]);
            b = b(1:end-1);
            r = stats(1);
    end

    betas(:,vox) = b;
    %rmsErrors(vox) = r;
end

fprintf('\n');

model = smSet(model, 'xform betas',  betas);
model = smSet(model, 'varexplained', rmsErrors);

%--------------------------------------------------------------
% Convert tramsform weights to pixel/voxel weights
%--------------------------------------------------------------
model = smXform2VoxelWeights(model);

return
