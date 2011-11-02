function [vw, model] = smSaveTSeriesImage(model, voxels, vw, scans)
%
% Create plots of predicted versus actual TSeries signal from a surface
% model of the BOLD response (see smMain.m).
%  
% [vw, model] = smSaveTSeriesImage(model, voxels, [vw], [scans])
%   
%   model:      a surface model (struct)
%   voxels:     a vector of voxel indices into the predicted ROI 
%   vw:         current mrVista view struct (must be a gray view)
%   scans:      a vector scans to plot. if not defined, then plot all
%               scans used for the regression (i.e., training data); if it
%               is defined, then assume this is test data, and get the data
%               from mrVista instead of from the stored model
%
% If, for example, V1 time series is used to predict V2 t-series, then each
% V2 voxel has an an actual signal and a corresponding predicted signal
% based on the model.
%
%  Example 1: Make TSeries image for a single dependent voxel in the
%  model
%    vw = getCurView;
%    voxel = 1;
%    [vw, model] = smSaveTSeriesImage(model, voxel, vw);    
%
%  Example 2: Make TSeries images for many dependent voxels
%    vw = getCurView;
%    voxels = 50:50:1000;
%    [vw, model] = smSaveTSeriesImage(model, voxels, vw);    
%
%  Example 3: Make TSeries images for test data (all scans in the dataTYPE
%               that were NOT included in the model)
%    vw = getCurView;
%    voxels = 50:50:1000;
%    scans = setdiff(1:viewGet(vw, 'nscans'), smGet(model, 'scans'));
%    [vw, model] = smSaveTSeriesImage(model, voxels, vw, scans);    

%----------------
% Variable check
%----------------
if notDefined('model'),     error('Need model');                end
if notDefined('voxels'),    error('Need to specify voxel(s)');  end
if notDefined('vw'),        vw = getCurView;                    end
if notDefined('scans'),     testData = false; scans = smGet(model, 'scans');  
else                        testData = true;                    end


%----------------
% Directory check
%----------------
imageDir = smGet(model, 'imageDirFull');


%-------------------
% Get t-series
%-------------------

%get the stimulus or predictor ROI vars(x_i's)
fprintf(1, '[%s]: The predictor is %s. Getting TSeries\n', ...
    mfilename, smGet(model, 'roiXname'));
if testData,    X = smGet(model, 'tSeriesXtestData', scans); 
else            X = smGet(model, 'tSeriesX'); end
        
        
%get theresponse variables (y_is)
if testData,    Y = smGet(model, 'tSeriesYtestData', scans); 
else            Y = smGet(model, 'tSeriesY'); end

% Center and scale as necessary 
%   TODO: add flags to model.params to indicate whether X and Y were
%   centered and/or z-scored in solving the regression, so that we can be
%   sure to do the same thing when plotting the t-series
X = zscore(X);
Y = center(Y);

%-------------------
% Get beta weights
%-------------------
betas =  smGet(model, 'voxelBetas');

if (size(X, 2) ~= size(betas, 2))
    error('dimensions of weights and predictor/x_is must match');
end

%-------------------
% Make the predictions
%-------------------
pred = X * betas';

%----------------
% Make images
%----------------
% set limits for x-axis on plots 
xrange = [1 100];

roiname = smGet(model, 'roiyname');

% Loop through voxels
for vox = voxels

   % Get the predicted and actual t-Series
    curPred = pred(:,vox);
    curActual = Y(:, vox);
    
    
    % Hack: there is a scaling error in the pRF model, so we zscore the
    % predictions and the real signal
    if strcmpi('prf', smGet(model, 'regressionType'))
       curPred = zscore(curPred);
       curActual = zscore(curActual);
    end
    
    % Get the stored and recomputed variance explained
    varexplained.model = smGet(model, 'varExplained', vox);
    SSerr = var(curActual - curPred);
    SStot = var(curActual);
    varexplained.recalculated = 1 - SSerr./SStot;
    
    % Name the voxel in order to title the plot
    roiYname = smGet(model, 'roiYname');
    coords = smGet(model, 'roiYcoords', vox);
    vname = sprintf('TSeries-%s-%d-[%d-%d-%d]', ...
        roiYname, vox, coords(1), coords(2), coords(3));
    titleString = sprintf...
        ('%s Voxel: %d\nVariance explained: %1.2f (stored); %1.2f (recalculated)\n',...
        roiname, vox, varexplained.model, varexplained.recalculated);
    if(testData)
        titleString = sprintf('%s Voxel: %d\nVariance explained: %1.2f (by training data); %1.2f (by test data)', ...
            roiname, vox, varexplained.model, varexplained.recalculated);
    end

    
 
     
    % Plot it
    f = figure('Color', 'w'); hold on;
    plot(1:length(curActual), curActual, 'r', 1:length(curActual), curPred, 'k--', 'LineWidth', 4);
    xlim(xrange);
    legend('Actual', 'Prediction');
    title(titleString, 'FontSize', 14);
    set(gca, 'XTick', [0:20:100], 'FontSize', 20);
    set(gca, 'Color', 'g');
    if testData,    saveas(f, fullfile(imageDir, ['Test-' vname '.jpg']));
    else            saveas(f, fullfile(imageDir, ['Training-' vname '.jpg'])); end
    close(f); clear f;

end