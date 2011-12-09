% rd_plotTopographicData.m

%% Setup
hemi = 2;
scanDate = '20111025';
analysisDate = '20111025';

voxelSelectionOption = 'all'; % ['all','anySuperthresh','loadVoxelSelector','training','varExp']
voxelSelectorPath = 'voxelSelector1_superthreshAll_AllScans_20110907.mat';
cmapOption = 'default'; % ['default','thresh']
cScaleOption = 'scaleToData'; % ['scaleToData','chooseCRange']
cValRange = [-.95 .95]; % if using chooseCRange
plotFigs = 1;
saveAnalysis = 0;
saveFigs = 0;

iROI = 1; % only plotting one ROI at a time here

%% File I/O
% fileBase = sprintf('lgnROI%dAnalysis_%s', hemi, scanDate);
% % analysisExtension = sprintf('_mpDistributionZ%s', analysisDate);
% analysisExtension = sprintf('_mpDistributionCorAnalOrtho%s', analysisDate);
% loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);
% mapFileBase = sprintf('lgnROI%dBrainMapTopoCoronal_%s_', hemi, scanDate);

fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);
mapFileBase = sprintf('lgnROI%dBrainMapTopoCoronal_', hemi);

%% Load data
load(loadPath)

%% Choose data to show here
% topoData = contrastData.co(:,1); % vals*coefNow'; % pScores; % corAnal.co; % contrasts.co(8).data; % zoContrasts(:,3); % should be a 1-D vector
betas = squeeze(figData.glm.betas(1,1:2,:))';
% topoData = betas*[-.5 .5 -.5 .5]';
% topoData = betas*[.5 -.5]';
% topoData = betas*[1 0]';
topoData = coData;
mapName = 'Co'; % sprintf('Hemi %d', hemi); % contrasts.zo(3).name;

%% Any voxel selection?
switch voxelSelectionOption
    case 'all'
        voxelSelector = logical(ones(1,length(topoData))); 
    case 'anySuperthresh'
%         voxelSelector = superthreshVoxs.co';
%         voxelSelector = any(corAnal.co>.19,2)';
        voxelSelector = any(superthreshAll,2)';
    case 'loadVoxelSelector'
        load(voxelSelectorPath)
        voxelSelector = voxelSelector';
    case 'training'
        voxelSelector = trainingVoxSelector;
    case 'testing'
        voxelSelector = testingVoxSelector;
    case 'varExp'
        varThresh = 0.005;
        voxelSelector = figData.glm.varianceExplained > varThresh;
    otherwise
        error('voxelSelectionOption not found');
end

%% Histogram of the values being mapped
figure
hist(topoData(voxelSelector))
title(mapName)

%% get coordinates and slice numbers of ROI voxels
% inplaneCoords{iROI} = data(1).lgnROICoords([2 1 3],:); % switch x and y
% inplaneSlices{iROI} = inplaneCoords{iROI}(3,:);

inplaneCoords{iROI} = figData.coordsInplane; % switch x and y??
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
    
    xycoords = inplaneCoords{iROI}(1:2,inSlice);
    vals = topoData(inSlice);
    
    allVals = [allVals; vals];
end

%% set up the color mapping
cmap0 = colormap('jet');
nCMappings = size(cmap0,1);

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
        thresh = 0;
        lowZThreshBin = find(diff(cmapBinEdges<-thresh));
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
    
    % find val cmap bins
    clear cBins
    for iVal = 1:length(vals)
        try
            cBins(iVal,1) = find(diff(vals(iVal)>cmapBinEdges));
        catch
            cBins(iVal,1) = find(diff(vals(iVal)>=cmapBinEdges));
        end
    end
    
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
            
            brainMapRGB(indcoords) = cmap(cBins,iChan);
        end
    end
 
    clear brainSliceMap
    for i=1:3
        %         brainSliceMap(:,:,i) = flipud(brainMapRGB(:,:,i)'); % **for testing only?**
        brainSliceMap(:,:,i) = flipud(brainMapRGB(:,:,i));
    end
    
    brainMap(:,:,:,iSlice) = brainSliceMap;
    
end % end for slice

%% plot brainMap 
xyCoordsToPlot = {1:size(brainMap,1)-minInplaneCoords(1)+1, ...
    minInplaneCoords(2)-1:size(brainMap,2)};
brainMapToPlot = brainMap(xyCoordsToPlot{1},xyCoordsToPlot{2},:,:);

dimLabels = {'Sag','Cor','--','Ax'};
dimToSlice = 2;

% number of subplots to contain all slices
% nPlotCols = ceil(sqrt(length(slices)));
% nPlotRows = ceil(length(slices)/nPlotCols);
nPlotCols = ceil(sqrt(size(brainMapToPlot,dimToSlice)));
nPlotRows = ceil(size(brainMapToPlot,dimToSlice)/nPlotCols);

f = figure('name',mapName);
for iSlice = 1:size(brainMapToPlot,dimToSlice)
    
    switch dimToSlice
        case 1 % (sagittal)
            if iSlice==1, fprintf('\n\nSlicing sagittal ...\n\n'), end
            brainSliceMap = shiftdim(squeeze(brainMapToPlot(iSlice,:,:,:)),2);
        case 2 % (coronal) viewing from the front, slices numbered from posterior to anterior
            if iSlice==1, fprintf('\n\nSlicing coronal ...\n\n'), end
            brainSliceMap0 = shiftdim(squeeze(brainMapToPlot(:,iSlice,:,:)),2);
            brainSliceMap1(:,:,1) = flipud(brainSliceMap0(:,:,1));
            brainSliceMap1(:,:,2) = flipud(brainSliceMap0(:,:,2));
            brainSliceMap1(:,:,3) = flipud(brainSliceMap0(:,:,3));
            brainSliceMap = brainSliceMap1;
        case 4 % standard (axial)
            if iSlice==1, fprintf('\n\nSlicing axial ...\n\n'), end
            brainSliceMap = brainMapToPlot(:,:,:,iSlice);
    end
    
    % show slice with colored map
    subplot(nPlotRows, nPlotCols, iSlice)
    image(brainSliceMap)
    if dimToSlice==4
        title(['Slice ' num2str(slices(iSlice))])
    else
        title(['Slice ' num2str(iSlice)])
    end
    axis off
    
end

%% save map
mapSavePath = sprintf('%s%s%s', mapFileBase, mapName, datestr(now,'yyyymmdd'));
if saveAnalysis
    save(sprintf('mat_files/%s.mat', mapSavePath), 'brainMap')
end
if saveFigs
    print(f,'-djpeg',sprintf('figures/%s', mapSavePath));
end



% %% plot brainMap (SAFE)
% xyCoordsToPlot = {1:size(brainMap,1)-minInplaneCoords(1)+1, ...
%     minInplaneCoords(2)-1:size(brainMap,2)};
% brainMapToPlot = brainMap(xyCoordsToPlot{1},xyCoordsToPlot{2},:,:);
% 
% figure
% for iSlice = 1:size(brainMap,4)
%     
% %     brainSliceMap = brainMap(:,:,:,iSlice);
%     brainSliceMap = brainMapToPlot(:,:,:,iSlice);
%     
%     % show slice with colored map
%     subplot(nPlotRows, nPlotCols, iSlice)
% %     image(brainSliceMap(xyCoordsToPlot{1},xyCoordsToPlot{2},:))
%     image(brainSliceMap)
%     title(['Slice ' num2str(slices(iSlice))])
%     axis off
%     
% end

