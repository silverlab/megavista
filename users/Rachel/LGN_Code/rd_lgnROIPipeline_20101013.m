% rd_lgnROIPipeline_20101013
%
% Setup: Load inplane window for average of all scans and ROIs 1-6

%% Get individual voxel time series from inplane ROIs
% ROINumbers = 1:6;
ROINumbers = 19:27;
[voxelTSeries, numPts, epiROICoords, tSeries] = rd_voxelTSeries(INPLANE{1},1,ROINumbers);

%% Combine into left and right LGN ROIs
lgnROI1All = [voxelTSeries{1} voxelTSeries{3} voxelTSeries{5}];
lgnROI2All = [voxelTSeries{2} voxelTSeries{4} voxelTSeries{6}];

%% Or do the same thing for single, catch-all LGN ROI:
%% 
lgnROI3All = cell2mat(voxelTSeries);
lgnROI3CoordsAll = cell2mat(epiROICoords);
dupVoxelPairs3 = rd_findDuplicateROICoords(lgnROI3CoordsAll)
dupVoxels3 = dupVoxelPairs3(:,2);
lgnROI3 = lgnROI3All;
lgnROI3(:, dupVoxels3) = [];
lgnROI3Coords = lgnROI3CoordsAll;
lgnROI3Coords(:, dupVoxels3) = [];

plotFlag = 0;
voxelNums = 1:size(lgnROI3,2);
[voxelFFT3 meanFFT3 data3] = ...
        rd_plotVoxelFFT(lgnROI3(:,voxelNums), INPLANE{1}, 1, plotFlag, voxelNums);
    
figure
hold on
scatter(voxelNums, data3.zScore)
plot([voxelNums(1) voxelNums(end)], [2.5 2.5], 'r', 'LineWidth', 2)
xlabel('voxel number')
ylabel('fft z-score')

zThreshs = [2.5 3 3.5];
for thresh = 1:length(zThreshs)
    z = zThreshs(thresh);
    w = data3.zScore>z;
    zThresh(thresh).z = z;
    zThresh(thresh).voxNums = find(w);
    zThresh(thresh).zScores = data3.zScore(w);
    zThresh(thresh).howMany = nnz(w);
end


%% Store ROI coordinates
lgnROI1CoordsAll = [epiROICoords{1} epiROICoords{3} epiROICoords{5}];
lgnROI2CoordsAll = [epiROICoords{2} epiROICoords{4} epiROICoords{6}];

%% Find duplicate voxels
dupVoxelPairs1 = rd_findDuplicateROICoords(lgnROI1CoordsAll)
dupVoxelPairs2 = rd_findDuplicateROICoords(lgnROI2CoordsAll)

%% Select only unique voxels (and their coords)
dupVoxels1 = dupVoxelPairs1(:,2);
dupVoxels2 = dupVoxelPairs2(:,2);

lgnROI1 = lgnROI1All;
lgnROI1(:, dupVoxels1) = [];
lgnROI2 = lgnROI2All;
lgnROI2(:, dupVoxels2) = [];

lgnROI1Coords = lgnROI1CoordsAll;
lgnROI1Coords(:, dupVoxels1) = [];
lgnROI2Coords = lgnROI2CoordsAll;
lgnROI2Coords(:, dupVoxels2) = [];

%% Compute and plot FFTs for ROI voxels 
plotFlag = 1;
voxelSets1 = {1:7, 8:14, 15:21};
for iSet = 1:length(voxelSets1)
    
    voxelNums = voxelSets1{iSet};
    
    [voxelFFT1{iSet} meanFFT1{iSet} data1{iSet}] = ...
        rd_plotVoxelFFT(lgnROI1(:,voxelNums), INPLANE{1}, 1, plotFlag, voxelNums);
    
end

voxelSets2 = {1:6, 7:12};
for iSet = 1:length(voxelSets2)
    
    voxelNums = voxelSets2{iSet};
    
    [voxelFFT2{iSet} meanFFT2{iSet} data2{iSet}] = ...
        rd_plotVoxelFFT(lgnROI2(:,voxelNums), INPLANE{1}, 1, plotFlag, voxelNums);
    
end

%% Compute and plot mean for left and right ROIs
lgnROI1Mean = mean(lgnROI1,2);
lgnROI2Mean = mean(lgnROI2,2);

rd_plotTSeries([lgnROI1Mean lgnROI2Mean], INPLANE{1}, 1);











