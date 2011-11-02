function [vw, model] = smSaveRFImage(model, voxels, vw, PCorVoxel)
% Create a Receptive Field image of model weights from a surface model.
%
% [vw, model] = smSaveRFImage(model, voxels, [vw], PCorVoxel)
%
% This works for models who's predictor is STIMULUS.
% If, for example, STIMULUS is used to predict V2 t-series, then each
% V2 voxel has an associated receptive field map(a map of weights). A map
% can also be made of the principal components on the STIMULUS, if PCs
% were used in the regression. Note that there is a distinct maps
% assocaited with each dependenet voxel in a model and a distinct map
% associated with each PC for the independent variable. Hence it is
% probably useful to subsample the voxels when making images (e.g., if your
% dependent ROI is V2 and V2 has 2000 voxels, you might not want to create
% an image for each of the 2000 voxels).
%
%  Example 1: Make regression maps for a single dependent voxel in the
%  model
%    vw = getCurView;
%    voxel = 1;
%    [vw, model] = smSaveRFImage(model, voxel, vw);    
%
%  Example 2: Make regression maps for many dependent voxels
%    vw = getCurView;
%    voxels = 50:50:1000;
%    [vw, model] = smSaveRFImage(model, voxels, vw);    
%
%  Example 3: Make  maps of first 10 PCs from the predictor ROI of a
%  surface model.
%  voxels.
%    vw = getCurView;
%    PCs = 1:10;
%    [vw, model] = smSaveRFImage(model, PCs, vw, 'PCs');

%----------------
% Variable check
%----------------
if notDefined('model'),     error('Need model');                end
if notDefined('voxels'),    error('Need to specify voxel(s)');  end
if notDefined('vw'), vw = getCurView; end
if notDefined('PCorVoxel'), PCorVoxel = 'voxel'; end

if (~strcmp(smGet(model, 'roiXname'), 'STIMULUS')) %model was predicted from ROI
    error('model is predicted from ROI, not stimulus. you can make mesh images but not rf images');
end

%----------------
% Directory check
%----------------
imageDir = smGet(model, 'imageDirFull');

%------------------------
% Get stimulus parameters
%------------------------
effectiveIndices = smGet(model, 'instimwindow');
stimWindowWidth  = sqrt(size(smGet(model, 'stimwindow'), 1));

%----------------
% Make images
%----------------
visualField = zeros(stimWindowWidth, stimWindowWidth);
roiYname = smGet(model, 'roiYname');
for vox = voxels
    
    if strcmpi(PCorVoxel, 'voxel')
        betas = smGet(model, 'pcBetas', vox);
        if (isempty(betas)) %assume prf
            curVoxelBetas = smGet(model, 'voxelBetas', vox);
        else
            latent = smGet(model, 'latent');
            coeffs = smGet(model, 'coeff');            
            reweighted = latent .* betas';
            curVoxelBetas = coeffs * reweighted;
            
            %delete me??? jw: remove the hack and see how bad it is:
            %--------------------------------------------------------
            curVoxelBetas = smGet(model, 'voxelBetas', vox);
            %--------------------------------------------------------
            
        end
        coords = smGet(model, 'roiYcoords', vox);            
        var = smGet(model, 'varExplained', vox);
        vname = sprintf('%s-%d-[%d-%d-%d]', ...
                roiYname, vox, coords(1), coords(2), coords(3));
    else
        pc = vox;
        curVoxelBetas = smGet(model, 'PCcoeff', pc);
        var = smGet(model, 'latent', vox) / sum(smGet(model, 'latent'));
        roiXname = smGet(model, 'roiXname');
        vname = sprintf('%s-PC-%d', roiXname, pc);
    end

    %surface model has negative values for voxelbetas. setting the pixels
    %outside of the circle to be the minimum value makes the images look
    %similar to the prf model
    %visualField = visualField + min(curVoxelBetas);
    visualField(effectiveIndices) = curVoxelBetas;
    f = figure; 
    hold on;
    visualField = flipud(visualField);
    imagesc(visualField);
    range = [-1 1] * max(abs(visualField(:)));
    set(gca, 'clim', range)
    x1 = zeros(stimWindowWidth,1);
    x1 = x1 + stimWindowWidth/2;
    y1 = 1:1:stimWindowWidth;
    plot(x1,y1,'black');
    x2 = y1;
    y2 = x1;
    plot(x2,y2,'black')
    %titleString = sprintf('%s\n%s\n variance explained = %0.2f', ...
    %    smGet(model, 'modelFile'), vname, var);
    titleString = sprintf('%s variance explained = %0.2f', vname, var);
    title(titleString, 'FontSize', 14);
    axis image off;
    colorbar;
    saveas(f, fullfile(imageDir, [vname '.jpg']));
    close(f);
    clear f;
end