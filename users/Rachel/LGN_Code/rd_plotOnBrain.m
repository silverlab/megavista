% rd_plotOnBrain

% make sure roi coords are loaded
load('lgnROI3Data_AvgScan1-6_20101029.mat')
% load('lgnROI3Data_AvgScan1-4_20101201.mat')

% scans = 1:6;
scans = 1:4;
inplaneDir = '../Inplane/Original/TSeries/Analyze';

% load roi data
load('mat_files/sigVoxROIData.mat')

% store data in structure
roiData(1).idx = roi1_idx;
roiData(1).phase = roi1_phase;
roiData(1).tval = roi1_tval;
roiData(1).pval = roi1_pval;

roiData(2).idx = roi2_idx;
roiData(2).phase = roi2_phase;
roiData(2).tval = roi2_tval;
roiData(2).pval = roi2_pval;

% generate a mean inplane from all scans (sort of like an anatomical)
for iScan = 1:length(scans)
    scan = scans(iScan);
    inplaneScan = readFileNifti(sprintf('%s/Scan%d.img',inplaneDir,scan));
    inplaneScanMeans(:,:,:,iScan) = mean(inplaneScan.data,4);
end

inplaneMean = mean(inplaneScanMeans,4);

% show inplane mean
figure
for i=1:size(inplaneMean,3)
    subplot(6,5,i)
    imagesc(inplaneMean(:,:,i))
    colormap gray
    axis off
end

% save (or load) inplane mean
save('mat_files/inplaneMean.mat', 'inplaneMean')
load('mat_files/inplaneMean.mat')

% get coordinates and slice numbers of ROI voxels 
for iROI = 1:2
    inplaneCoords{iROI} = lgnROI3Coords([2 1 3], roiData(iROI).idx); % switch x and y
    inplaneSlices{iROI} = inplaneCoords{iROI}(3,:);
end

% get relevant inplane slices
slices = sort(unique(cell2mat(inplaneSlices)));
inplaneMeanSlices = inplaneMean(:,:,slices); %3D

% plot inplane slices as rgb with data overlaid
rgbChannels = [1 2 3];
mapChannels = [1 3]; % roi1 in red, roi2 in blue
nPlotCols = ceil(sqrt(length(slices)));
nPlotRows = ceil(length(slices)/nPlotCols);

% may want the minimum color val to be > 0
valBase = .5;
valScale = (1-valBase);

% plot map on brain
figure
brainMap = zeros([size(inplaneMean(:,:,1)) 3 length(slices)]);
for iSlice = 1:length(slices)
    for iROI = 1:2
        
        mapChannel = mapChannels(iROI);
        otherChannels = rgbChannels;
        otherChannels(otherChannels==mapChannel) = [];
        
        inSlice = inplaneSlices{iROI}==slices(iSlice);

        xycoords = inplaneCoords{iROI}(1:2,inSlice);
        vals = roiData(iROI).tval(inSlice); % choose val to show here
        valsScaled = ((vals - min(vals))./max(vals))*valScale + valBase;
        
        % the first time through, make the base brain picture
        if iROI==1 
            brainSlice = inplaneMeanSlices(:,:,iSlice);
            brainSliceScaled = (brainSlice - min(min(brainSlice)))./max(max(brainSlice));
            brainSliceRGB = cat(3, brainSliceScaled, brainSliceScaled, brainSliceScaled);

            brainMapRGB = brainSliceRGB;
            sliceDims = size(brainMapRGB);
        end
        
        % add the roi map
        if ~isempty(vals)
            indcoords = sub2ind(sliceDims, xycoords(1,:), xycoords(2,:), ...
                repmat(mapChannel, 1, size(xycoords,2)));

            brainMapRGB(indcoords) = valsScaled;

            for iChan = 1:length(otherChannels)
                indcoords_nomap = sub2ind(sliceDims, ...
                    xycoords(1,:), xycoords(2,:), ...
                    repmat(otherChannels(iChan), 1, size(xycoords,2)));

                brainMapRGB(indcoords_nomap) = 0;
            end
        end

    end % end for ROI
    
    for i=1:3
        brainSliceMap(:,:,i) = flipud(brainMapRGB(:,:,i)');
    end
    
    brainMap(:,:,:,iSlice) = brainSliceMap;

    % show slice with colored map
    subplot(nPlotRows, nPlotCols, iSlice)
    image(brainSliceMap)
    title(['Slice ' num2str(slices(iSlice))])
    axis off

end % end for slice

% save map
save('mat_files/brainMap_tval.mat', 'brainMap')

% plot brainMap if it's loaded directly
figure
for iSlice = 1:size(brainMap,4)
    
    brainSliceMap = brainMap(:,:,:,iSlice);

    % show slice with colored map
    subplot(nPlotRows, nPlotCols, iSlice)
    image(brainSliceMap(60:110,20:100,:)) % 60:110,20:100 / 40:80,40:80
    title(['Slice ' num2str(slices(iSlice))])
    axis off
    
end





