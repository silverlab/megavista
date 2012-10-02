function rd_plotTopographicData2SatFn(hemi, voxelSelectionOption, ...
    saturationOption, betaWeights, name, varThresh, saveFigs)
%
% function rd_plotTopographicData2Fn(hemi, voxelSelectionOption, ...
%     saturationOption, betaWeights, name, varThresh)
%
% use this version for GLM data for natural left/right orientations
%
% INPUTS:
% hemi is 1 or 2
% voxelSelectionOption is typically 'all' or 'varExp'
% saturationOption can be 'full' or 'varExp'. scales the saturation of
% the voxel color according to the selected variable.
% betaWeights is a 1x2 vector with weights for compining M and P betas (eg,
% [.5 -.5] for M-P)
% name is the name of this combo (eg, 'betaM-P')
% varThresh is the variance explained threshold if voxelSelectionOption is
% 'varExp'. can be [] if voxelSelctionOption is not 'varExp'.

%% Setup
cmapOption = 'default'; % ['default','thresh']
plotFormat = 'default'; % ['default','singleRow'] % singleRow plots slices in a row, and in reverse order. only tested for coronal slices.
switch name
    case 'betaM'
        colormapName = 'whitered';
    case 'betaP'
        colormapName = 'whiteblue';
    case 'betaM-P'
        colormapName = 'lbmap';
    otherwise
        fprintf('colormapName assignment not found. Setting colormap = jet')
        colormapName = 'jet';
end
% colormapName = 'whitered'; % ['whitered','whiteblue','lbmap', otherwise > 'jet']
cScaleOption = 'scaleToData'; % ['scaleToData','chooseCRange']
cValRange = [-.95 .95]; % if using chooseCRange
saveAnalysis = 0;

iROI = 1; % only plotting one ROI at a time here

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);
mapFileBase = sprintf('lgnROI%dBrainMapTopoCoronal_', hemi);
histFileBase = sprintf('lgnROI%dHist_', hemi);

switch voxelSelectionOption
    case 'all'
        voxDescrip = 'all';
    case 'varExp' 
        threshDescrip = sprintf('%0.03f', varThresh);
        voxDescrip = ['varThresh' threshDescrip(3:end)];
    otherwise
        error('voxelSelectionOption not found when setting voxDescrip.')
end

switch saturationOption
    case 'full'
        satDescrip = '';
    case 'varExp'
        satDescrip = 'satVarExp_';
    otherwise
        error('saturationOption not found when setting satDescrip.')
end

%% Load data
load(loadPath)

%% Choose data to show here
betas = squeeze(figData.glm.betas(1,1:2,:))';
topoData = betas*betaWeights';
mapName = sprintf('Hemi %d %s %s %s', hemi, name, voxDescrip, satDescrip);

%% Any voxel selection?
switch voxelSelectionOption
    case 'all'
        voxelSelector = logical(ones(1,length(topoData))); 
    case 'loadVoxelSelector'
        load(voxelSelectorPath)
        voxelSelector = voxelSelector';
    case 'varExp'
        voxelSelector = figData.glm.varianceExplained > varThresh;
    otherwise
        error('voxelSelectionOption not found');
end

%% Any voxel color saturation scaling?
switch saturationOption
    case 'full'
        saturationLevels = ones(1,length(topoData)); 
    case 'varExp'
        saturationLevels = figData.glm.varianceExplained;
        saturationLevels = saturationLevels./max(saturationLevels); % scale to have max of 1
    otherwise
        error('saturationOption not found');
end

%% Histogram of the values being mapped
f0 = figure;
hist(topoData(voxelSelector))
xlabel(name)
ylabel('number of voxels')
title(mapName)

%% get coordinates and slice numbers of ROI voxels
inplaneCoords{iROI} = figData.coordsInplane;
inplaneSlices{iROI} = figData.coordsInplane(3,:);

%% 'inplane mean' - just a black background
inplaneMean = zeros(max(inplaneCoords{1}'));
slices = min(inplaneCoords{1}(3,:)):max(inplaneCoords{1}(3,:));
inplaneMeanSlices = inplaneMean(:,:,slices); %3D
minInplaneCoords = min(inplaneCoords{1}');

%% first find all vals to plot to set cmap
allVals = [];
for iSlice = 1:length(slices)
    inSlice = inplaneSlices{iROI}==slices(iSlice);
    
    vals = topoData(inSlice);
    
    allVals = [allVals; vals];
end

%% set up the color mapping
cmap0 = colormap('jet');
nCMappings = size(cmap0,1);

switch colormapName
    case 'whitered'
        whitered = zeros(size(cmap0));
        whitered(:,1) = 1;
        whitered(:,2) = 1:-1/(nCMappings-1):0;
        whitered(:,3) = 1:-1/(nCMappings-1):0;
        cmap0 = whitered;
    case 'whiteblue'
        whiteblue = zeros(size(cmap0));
        whiteblue(:,3) = 1;
        whiteblue(:,1) = 1:-1/(nCMappings-1):0;
        whiteblue(:,2) = 1:-1/(nCMappings-1):0;
        cmap0 = whiteblue;
    case 'lbmap'
        cmap0 = colormap(flipud(lbmap(nCMappings,'redblue')));
end

switch cScaleOption
    case 'scaleToData'
        cmapBinSize = (max(allVals)-min(allVals))/nCMappings;
        cmapBinEdges = min(allVals):cmapBinSize:max(allVals);
    case 'chooseCRange'
        cmapBinSize = (cValRange(2)-cValRange(1))/nCMappings;
        cmapBinEdges = cValRange(1):cmapBinSize:cValRange(2);
    otherwise
        error('cscaleOption not found.')
end
fprintf('\ncmap ranges from %.02f to %.02f\n\n',cmapBinEdges(1), cmapBinEdges(end))

switch cmapOption
    case 'default'
        cmap = cmap0;
    case 'thresh'
        thresh = 0.66;
        lowZThreshBin = find(diff(cmapBinEdges<thresh)); % use <-thresh to threshold on either side of zero
        highZThreshBin = find(diff(cmapBinEdges>thresh));
        cmap = zeros(size(cmap0));
        cmap(1:lowZThreshBin,:) = repmat(cmap0(1,:),lowZThreshBin,1);
        cmap(highZThreshBin:end,:) = ...
            repmat(cmap0(end,:),nCMappings-highZThreshBin+1,1);
        cmap(lowZThreshBin+1:highZThreshBin-1,:) = ...
            repmat(cmap0(end/2,:),highZThreshBin-lowZThreshBin-1,1);
    otherwise
        error('cmapOption not found.')
end

%% make rgb map in 3D space
brainMap = zeros([size(inplaneMean(:,:,1)) 3 length(slices)]);

for iSlice = 1:length(slices)
    
    inSlice = inplaneSlices{iROI}==slices(iSlice);
    w = inSlice & voxelSelector;
    
    xycoords = inplaneCoords{iROI}(1:2,w);
    vals = topoData(w); % choose val to show here
    sats = saturationLevels(w)'; % choose saturation levels
    
    % find val cmap bins
    clear cBins
    if isempty(vals)
        cBins = [];
    else
        for iVal = 1:length(vals)
            try
                cBins(iVal,1) = find(diff(vals(iVal)>cmapBinEdges));
            catch
                cBins(iVal,1) = find(diff(vals(iVal)>=cmapBinEdges));
            end
        end
    end
    
    % modulate the color values by saturation level
    rgbVals = cmap(cBins,:);
    hsvVals = rgb2hsv(rgbVals);
    vVals = hsvVals(:,3);
    hsvSVals = hsvVals;
    hsvSVals(:,3) = vVals.*sats;
    rgbSVals = hsv2rgb(hsvSVals);
    
    % make the base brain picture
    brainSlice = inplaneMeanSlices(:,:,iSlice);
    brainSliceRGB = cat(3, brainSlice, brainSlice, brainSlice);
    brainMapRGB = brainSliceRGB;
    sliceDims = size(brainMapRGB);
    
    % add the roi map
    if ~isempty(vals)
        for iChan = 1:3
            indcoords = sub2ind(sliceDims, xycoords(1,:), xycoords(2,:), ...
                repmat(iChan, 1, size(xycoords,2)));
            
%             brainMapRGB(indcoords) = cmap(cBins,iChan); % ORIG
            brainMapRGB(indcoords) = rgbSVals(:,iChan);
            
        end
    end
 
    clear brainSliceMap
    for i=1:3
        brainSliceMap(:,:,i) = flipud(brainMapRGB(:,:,i));
    end
    
    brainMap(:,:,:,iSlice) = brainSliceMap;
    
end % end for slice

%% plot brainMap 
xyCoordsToPlot = {1:size(brainMap,1)-minInplaneCoords(1)+1, ...
    minInplaneCoords(2):size(brainMap,2)};
brainMapToPlot = brainMap(xyCoordsToPlot{1},xyCoordsToPlot{2},:,:);

dimLabels = {'Sag','Cor','--','Ax'};
dimToSlice = 2;

% number of subplots to contain all slices
switch plotFormat
    case 'default'
        nPlotCols = ceil(sqrt(size(brainMapToPlot,dimToSlice)));
        nPlotRows = ceil(size(brainMapToPlot,dimToSlice)/nPlotCols);
    case 'singleRow'
        nPlotCols = size(brainMapToPlot,dimToSlice);
        nPlotRows = 1;
    otherwise
        error('plotFormat not recognized')
end

f1 = figure('name',mapName);
for iSlice = 1:size(brainMapToPlot,dimToSlice)
    brainSliceMap1 = [];
    switch dimToSlice
        case 1 % (sagittal)
            if iSlice==1, fprintf('\n\nSlicing sagittal ...\n\n'), end
            brainSliceMap = shiftdim(squeeze(brainMapToPlot(iSlice,:,:,:)),2);
        case 2 % (coronal) viewing from the front, slices numbered from posterior to anterior
            if iSlice==1, fprintf('\n\nSlicing coronal ...\n\n'), end
            brainSliceMap0 = shiftdim(squeeze(brainMapToPlot(:,iSlice,:,:)),2);
            brainSliceMap1(:,:,1) = fliplr(flipud(brainSliceMap0(:,:,1)));
            brainSliceMap1(:,:,2) = fliplr(flipud(brainSliceMap0(:,:,2)));
            brainSliceMap1(:,:,3) = fliplr(flipud(brainSliceMap0(:,:,3)));
            brainSliceMap = brainSliceMap1;
        case 4 % standard (axial)
            if iSlice==1, fprintf('\n\nSlicing axial ...\n\n'), end
            brainSliceMap0 = brainMapToPlot(:,:,:,iSlice);
            brainSliceMap1(:,:,1) = flipud(brainSliceMap0(:,:,1));
            brainSliceMap1(:,:,2) = flipud(brainSliceMap0(:,:,2));
            brainSliceMap1(:,:,3) = flipud(brainSliceMap0(:,:,3));
            brainSliceMap = brainSliceMap1;
    end
    
    % store brain slice maps
    brainSliceMaps{iSlice} = brainSliceMap;
    
    % show slice with colored map
    switch plotFormat
        case 'default'
            subplot(nPlotRows, nPlotCols, iSlice)
        case 'singleRow' % plots slices in reverse order
            subplot(nPlotRows, nPlotCols, nPlotCols+1-iSlice)
        otherwise
            error('plotFormat not recognized')
    end
    
    image(brainSliceMap)
    if dimToSlice==4
        title(['Slice ' num2str(slices(iSlice))])
    else
        title(['Slice ' num2str(iSlice)])
    end
    axis off
    
    if strcmp(plotFormat, 'singleRow')
        axis equal
        axis tight
    end
    
end

%% save map
mapSavePath = sprintf('%s%s_%s_%s%s', mapFileBase, name, voxDescrip, satDescrip, datestr(now,'yyyymmdd'));
histSavePath = sprintf('%s%s_%s_%s', histFileBase, name, voxDescrip, datestr(now,'yyyymmdd'));

if saveAnalysis
    save(sprintf('%s.mat', mapSavePath),'brainMap','brainSliceMaps','dimToSlice','dimLabels','mapName','hemi','name','voxDescrip','satDescrip')
end
if saveFigs
    print(f1,'-djpeg',sprintf('figures/%s', mapSavePath));
%     print(f0,'-djpeg',sprintf('figures/%s', histSavePath));
end

