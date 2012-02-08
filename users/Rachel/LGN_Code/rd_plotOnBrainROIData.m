% rd_plotOnBrainROIData.m
%
% More general than rd_plotOnBrainZContrast.m

%% Setup
hemi = 1;
scanDate = '20110819';
analysisDate = '20110819';

cmapOption = 'default';
plotFigs = 1;
saveAnalysis = 0;

%% File I/O
fileBase = sprintf('lgnROI%dAnalysis_%s', hemi, scanDate);
analysisExtension = sprintf('_mpDistributionZ%s', analysisDate);
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);
mapFileBase = sprintf('lgnROI%dBrainMap_%s_z', hemi, scanDate);

%% Load data
load(loadPath)

%% Set data by hand
roiData = zoContrasts;
dataNames = cell(length(contrasts.zo),1);
[dataNames{:}] = deal(contrasts.zo.name);
dataIdx = 4;

%% get coordinates and slice numbers of ROI voxels 
for iROI = 1
    inplaneCoords{iROI} = data(1).lgnROICoords([2 1 3],:); % switch x and y
    inplaneSlices{iROI} = inplaneCoords{iROI}(3,:);
end

%% Load inplane mean if one already exists
load('mat_files/inplaneMean.mat')

%% generate a mean inplane from one or more scans (sort of like an anatomical)
scans = 1;
inplaneDir = '../../Inplane/Original/TSeries/Analyze';

for iScan = 1:length(scans)
    scan = scans(iScan);
    inplaneScan = readFileNifti(sprintf('%s/Scan%d.img',inplaneDir,scan));
    inplaneScanMeans(:,:,:,iScan) = mean(inplaneScan.data,4);
end

inplaneMean = mean(inplaneScanMeans,4);

%% show inplane mean
nImCols = ceil(sqrt(size(inplaneMean,3)));
nImRows = ceil(size(inplaneMean,3)/nImCols);

figure
for i=1:size(inplaneMean,3)
    subplot(nImRows,nImCols,i)
    imagesc(inplaneMean(:,:,i))
    colormap gray
    axis off
end

%% save (or load) inplane mean
save('mat_files/inplaneMean.mat', 'inplaneMean')

%% get relevant inplane slices
slices = sort(unique(cell2mat(inplaneSlices)));
inplaneMeanSlices = inplaneMean(:,:,slices); %3D

%% **FAKE INPLANE MEAN (for testing)**
% inplaneMean = zeros(max(inplaneCoords{1}'));
% slices = min(inplaneCoords{1}(3,:)):max(inplaneCoords{1}(3,:));
% inplaneMeanSlices = inplaneMean(:,:,slices); %3D

%% number of subplots to contain all slices
nPlotCols = ceil(sqrt(length(slices)));
nPlotRows = ceil(length(slices)/nPlotCols);

%% first find all vals to plot to set cmap
allVals = [];
for iSlice = 1:length(slices)
    for iROI = 1

        inSlice = inplaneSlices{iROI}==slices(iSlice);
        
        xycoords = inplaneCoords{iROI}(1:2,inSlice);
        vals = roiData(inSlice,dataIdx);
        
        allVals = [allVals; vals];
    end
end

%% set up the color mapping
cmap0 = colormap('jet');
nCMappings = size(cmap0,1);
cmapBinSize = (max(allVals)-min(allVals))/nCMappings;
cmapBinEdges = min(allVals):cmapBinSize:max(allVals);

switch cmapOption
    case 'default'
        cmap = cmap0;
    case 'thresh'
        thresh = .5;
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

%% plot inplane slices as rgb with data overlaid
figure
brainMap = zeros([size(inplaneMean(:,:,1)) 3 length(slices)]);

for iSlice = 1:length(slices)
    for iROI = 1
        
        inSlice = inplaneSlices{iROI}==slices(iSlice);

        xycoords = inplaneCoords{iROI}(1:2,inSlice);
        vals = roiData(inSlice,dataIdx); % choose val to show here
        
        % find val cmap bins
        clear cBins
        for iVal = 1:length(vals)
            try
                cBins(iVal,1) = find(diff(vals(iVal)>cmapBinEdges));
            catch
                cBins(iVal,1) = find(diff(vals(iVal)>=cmapBinEdges));
            end
        end
        
        % the first time through, make the base brain picture
        if iROI==1 
            brainSlice = inplaneMeanSlices(:,:,iSlice);
            if max(max(brainSlice))==0
                brainSliceScaled = brainSlice - min(min(brainSlice));
            else
                brainSliceScaled = (brainSlice - min(min(brainSlice)))./max(max(brainSlice));
            end
            brainSliceRGB = cat(3, brainSliceScaled, brainSliceScaled, brainSliceScaled);

            brainMapRGB = brainSliceRGB;
            sliceDims = size(brainMapRGB);
        end
        
        % add the roi map
        if ~isempty(vals)
            for iChan = 1:3
                indcoords = sub2ind(sliceDims, xycoords(1,:), xycoords(2,:), ...
                    repmat(iChan, 1, size(xycoords,2)));
                
                brainMapRGB(indcoords) = cmap(cBins,iChan);
            end
        end

    end % end for ROI
    
    for i=1:3
        brainSliceMap(:,:,i) = flipud(brainMapRGB(:,:,i)'); % **for testing only?**
%         brainSliceMap(:,:,i) = flipud(brainMapRGB(:,:,i));
    end
    
    brainMap(:,:,:,iSlice) = brainSliceMap;
    
    startpx = [0 1];
%     startpx = min(inplaneCoords{1}(1:2,:),[],2); % optional to show partial slice

    % show slice with colored map
    subplot(nPlotRows, nPlotCols, iSlice)
%     image(brainSliceMap)
    image(brainSliceMap(1:end-startpx(1),startpx(2):end,:))
    title(['Slice ' num2str(slices(iSlice))])
    axis off

end % end for slice

%% save map
mapSavePath = ...
    sprintf('mat_files/%s%s%s.mat', mapFileBase, dataNames{dataIdx}, datestr(now,'yyyymmdd'));
save(mapSavePath, 'brainMap')

%% plot brainMap if it's loaded directly or has already been generated
figure
for iSlice = 1:size(brainMap,4)
    
    brainSliceMap = brainMap(:,:,:,iSlice);

    % show slice with colored map
    subplot(nPlotRows, nPlotCols, iSlice)
    image(brainSliceMap(60:80,70:90,:)) % 60:110,20:100 / 40:80,40:80
    title(['Slice ' num2str(slices(iSlice))])
    axis off
    
end





