% rd_lgnROIPipeline_20101118
%
% Setup: Load inplane window for desired scans and ROIs 1-6, 19-27
%% Choose scan
scan = 1;

%% Get individual voxel time series from inplane ROIs
% ROINumbers = 1:6; % left and right LGN ROIs
ROINumbers = 19:27; % bilateral catch-all LGN ROIs
[voxelTSeries, numPts, epiROICoords, tSeries] = rd_voxelTSeries(INPLANE{1},scan,ROINumbers);

%% Combine into left and right LGN ROIs
lgnROI1All = [voxelTSeries{1} voxelTSeries{3} voxelTSeries{5}];
lgnROI2All = [voxelTSeries{2} voxelTSeries{4} voxelTSeries{6}];

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
plotFlag = 0;
% voxelSets1 = {1:7, 8:14, 15:21}; % Run02_MoreCoverage
voxelSets1 = {1:61}; % Run01_HighRes
zScores1 = [];
for iSet = 1:length(voxelSets1)
    
    voxelNums = voxelSets1{iSet};
    
    [voxelFFTRaw1{iSet} voxelFFT1{iSet} meanFFT1{iSet} data1{iSet}] = ...
        rd_plotVoxelFFT(lgnROI1(:,voxelNums), INPLANE{1}, scan, plotFlag, voxelNums);
    
    zScores1 = [zScores1; data1{iSet}.zScore'];
end

% voxelSets2 = {1:6, 7:12}; % Run02_MoreCoverage
voxelSets2 = {1:34}; % Run01_HighRes
zScores2 = [];
for iSet = 1:length(voxelSets2)
    
    voxelNums = voxelSets2{iSet};
    
    [voxelFFTRaw2{iSet} voxelFFT2{iSet} meanFFT2{iSet} data2{iSet}] = ...
        rd_plotVoxelFFT(lgnROI2(:,voxelNums), INPLANE{1}, scan, plotFlag, voxelNums);
    
    zScores2 = [zScores2; data2{iSet}.zScore'];
end

%% Plot z-scores
figure
subplot(1,2,1)
hold on
scatter(1:length(zScores1), zScores1)
plot([1 length(zScores1)], [2.5 2.5], 'r', 'LineWidth', 2)
xlabel('voxel number')
ylabel('fft z-score')

subplot(1,2,2)
hold on
scatter(1:length(zScores2), zScores2)
plot([1 length(zScores2)], [2.5 2.5], 'r', 'LineWidth', 2)
xlabel('voxel number')
ylabel('fft z-score')

%% Compute and plot mean for left and right ROIs
lgnROI1Mean = mean(lgnROI1,2);
lgnROI2Mean = mean(lgnROI2,2);

rd_plotTSeries([lgnROI1Mean lgnROI2Mean], INPLANE{1}, scan);

%% Save lgnROI1/lgnROI2 data
scanName = sprintf('Scan%d', scan);
% scanName = 'AvgScan1-6';
filename = sprintf('ROIAnalysis/lgnROI1-2Data_%s_%s.mat', scanName, datestr(now,'yyyymmdd'));
if exist(filename, 'file')
    error('A file with this name already exists ... File not saved.')
else
    save(filename, ...
        'lgnROI1', 'lgnROI1Coords', 'voxelSets1', 'voxelFFTRaw1', 'voxelFFT1', 'meanFFT1', 'data1', 'zScores1', 'lgnROI1Mean', ...
        'lgnROI2', 'lgnROI2Coords', 'voxelSets2', 'voxelFFTRaw2', 'voxelFFT2', 'meanFFT2', 'data2', 'zScores2', 'lgnROI2Mean')
end

%% Or do the same thing for single, catch-all LGN ROI:
%% Combine timeseries into single ROI, find coords, remove dups
lgnROI3All = cell2mat(voxelTSeries);
lgnROI3CoordsAll = cell2mat(epiROICoords);
dupVoxelPairs3 = rd_findDuplicateROICoords(lgnROI3CoordsAll);
dupVoxels3 = dupVoxelPairs3(:,2);
lgnROI3 = lgnROI3All;
lgnROI3(:, dupVoxels3) = [];
lgnROI3Coords = lgnROI3CoordsAll;
lgnROI3Coords(:, dupVoxels3) = [];

%% FFT, plot z-score
plotFlag = 0;
voxelNums = 1:size(lgnROI3,2);
[voxelFFTRaw3 voxelFFT3 meanFFT3 data3] = ...
        rd_plotVoxelFFT(lgnROI3(:,voxelNums), INPLANE{1}, scan, plotFlag, voxelNums);
    
figure
hold on
scatter(voxelNums, data3.zScore)
plot([voxelNums(1) voxelNums(end)], [2.5 2.5], 'r', 'LineWidth', 2)
xlabel('voxel number')
ylabel('fft z-score')

%% Find voxels with z-scores > a threshold
zThreshs = [0 2 2.5 3 3.5];
for thresh = 1:length(zThreshs)
    z = zThreshs(thresh);
    w = data3.zScore>z;
    zThresh(thresh).z = z;
    zThresh(thresh).voxNums = find(w);
    zThresh(thresh).zScores = data3.zScore(w);
    zThresh(thresh).howMany = nnz(w);
end

%% Sort good voxels by phase
voxelFFTPhase3 = unwrap(angle(voxelFFTRaw3));
signalFreqIdx = 8;

goodThresh = 2.5;
goodThreshIdx = find(zThreshs==goodThresh);
goodVoxNums = zThresh(goodThreshIdx).voxNums;

goodVoxTSeries = lgnROI3(:,goodVoxNums);
goodVoxFFTPhase = voxelFFTPhase3(:,goodVoxNums);
goodVoxFFTSignalPhase = goodVoxFFTPhase(signalFreqIdx,:);

figure
hist(goodVoxFFTSignalPhase,24)
% getting weird phases! (come back)


%% Save lgnROI3 data
% scanName = sprintf('Scan%d', scan);
scanName = 'AvgScan1-4';
filename = sprintf('ROIAnalysis/lgnROI3Data_%s_%s.mat', scanName, datestr(now,'yyyymmdd'));
if exist(filename, 'file')
    error('A file with this name already exists ... File not saved.')
else
    save(filename, 'lgnROI3', 'lgnROI3Coords', 'voxelFFTRaw3', 'voxelFFT3', 'meanFFT3', 'data3', 'zThresh')
end





