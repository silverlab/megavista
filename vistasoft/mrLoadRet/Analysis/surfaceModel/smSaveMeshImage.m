function [vw, model] = smSaveMeshImage(model, voxels, vw, PCorVoxel)
% Create an image of model weights from a surface model visualized on a mesh
%   (see smMain.m). 
% [vw, model] = smSaveMeshImage(model, voxels, [vw], PCorVoxel)
%
% If, for example, V1 time series is used to predict V2 t-series, then each
% V2 voxel has an associated V1 regression map (a map of weights). A map
% can also be made of the principal components on the V1 t-series, if PCs
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
%    [vw, model] = smSaveMeshImage(model, voxel, vw);    
%
%  Example 2: Make regression maps for many dependent voxels
%    vw = getCurView;
%    voxels = 50:50:1000;
%    [vw, model] = smSaveMeshImage(model, voxels, vw);    
%
%  Example 3: Make  maps of first 10 PCs from the predictor ROI of a
%  surface model.
%  voxels.
%    vw = getCurView;
%    PCs = 1:10;
%    [vw, model] = smSaveMeshImage(model, PCs, vw, 'PCs');    

%----------------
% Variable check
%----------------
if notDefined('model'), error('Need model'); end
if notDefined('voxels'), error('Need to specify voxel(s)'); end
if notDefined('vw'), vw = getCurView; end
if notDefined('PCorVoxel'), PCorVoxel = 'voxel'; end


%----------------
% Directory check
%----------------
imageDir = smGet(model, 'imageDirFull');
    
%----------------
% Make images
%----------------
vw = smLoadROIs(model, vw);
vw = smLoadMeshes(model, vw);
for vox = voxels
        
    if strcmpi(PCorVoxel, 'voxel'),
        % load a parameter map
        vw = smMakeParameterMap(model, vox, vw);
        % create a point-ROI for the VOI in order to display it on the mesh
        vw = smPointROI(model, vox, vw);
    
        % name the voxel by its index, its 3D coords, and its var explained
        var = smGet(model, 'varExplained', vox);
        roiYname = smGet(model, 'roiYname');
        coords = smGet(model, 'roiYcoords', vox);
        vname = sprintf('%s-%d-[%d-%d-%d]', ...
            roiYname, vox, coords(1), coords(2), coords(3));
    else
        % load a parameter map
        pc = vox;
        var = smGet(model, 'latent', vox) / sum(smGet(model, 'latent')) ;
        vw = smMakePCMap(model, pc, vw);
        roiXname = smGet(model, 'roiXname');
        vname = sprintf('%s-PC-%d',roiXname, pc);
    end

    % update the mesh
    vw.ui.mapMode=setColormap(vw.ui.mapMode, 'jetCmap'); 
    vw = refreshScreen(vw,0);
    vw = meshColorOverlay(vw);
    
    % save an image of the mesh
    img = mrmGet( viewGet(vw, 'Mesh'), 'screenshot' ) ./ 255;
    hTmp = figure('Color', 'w');
    imagesc(img);
    axis image; axis off;
    %headerstr = sprintf('%s\n%s\n variance explained = %0.2f',...
    %    smGet(model, 'modelFile'), vname, var);
    headerstr = sprintf('%s variance explained = %0.2f', vname, var);
    title(headerstr, 'FontSize', 14);

    saveas(hTmp, fullfile(imageDir, [vname '.jpg']));
    close(hTmp); clear hTmp;

    % get ready to start again by clearing the ROIs, refreshing the view
    if strcmpi(PCorVoxel, 'voxel'), 
        vw=deleteROI(vw,vw.selectedROI); vw=refreshScreen(vw,0);
    end  
end

% close the window
% vw = meshCloseWindow(vw);

return