% rd_lgnROIPipeline_mpLocalizer_20110819.m
%
% Setup: Load inplane window for desired scans and ROIs
%% Choose scan and hemisphere
scan = 4;
hemi = 2; % 1 = left, 2 = right

% Set ROI numbers
switch hemi
    case 1 % left/blue
%         ROINumbers = 1:12; % CG
%         ROINumbers = 1:14; % WC_20110731, defined on volume
%         ROINumbers = 30:42; % WC_20110731, defined on inplane
%         ROINumbers = 103; % WC_20110731, sphere defined on volume
%         ROINumbers = 1060; % WC_20110731 (106r)
        ROINumbers = 110; % WC PD
    case 2 % right/yellow
%         ROINumbers = 13:26; % CG
%         ROINumbers = 15:28; % WC_20110731, defined on volume
%         ROINumbers = 43:56; % WC_20110731, defined on inplane
%         ROINumbers = 203; % WC_20110731, sphere defined on volume
%         ROINumbers = 2060; % WC_20110731 (206r)
        ROINumbers = 210; % WC PD
    otherwise
        error('hemi not found.')
end

%% File I/O
fullScanName = dataTYPES(2).scanParams(scan).annotation; % 1 for Orig, 2 for Averages
scanName1st = textscan(fullScanName,'%s',1);
scanName = ['Avg' scanName1st{1}{1}] % 'Orig' or 'Avg'
fileBase = sprintf('lgnROI%dData_%s_%s', hemi, scanName, datestr(now,'yyyymmdd'));
savePath = sprintf('%s.mat', fileBase);
meanFigSavePath = sprintf('figures/%s_meanTSeries', fileBase);
zFigSavePath = sprintf('figures/%s_zScores', fileBase);

saveSummaryFigs = 1;

%% Get individual voxel time series from inplane ROIs
[voxelTSeries, numPts, epiROICoords, tSeries] = rd_voxelTSeries(INPLANE{1},scan,ROINumbers);

%% Combine timeseries into single ROI, find coords
lgnROIAll = cell2mat(voxelTSeries);
lgnROICoordsAll = cell2mat(epiROICoords);

%% Remove dups
lgnROI = lgnROIAll;
lgnROICoords = lgnROICoordsAll;
dupVoxelPairs = 0;
nDupLoops = 0;
while ~isempty(dupVoxelPairs) && nDupLoops < 10
    dupVoxelPairs = rd_findDuplicateROICoords(lgnROICoords);
    if ~isempty(dupVoxelPairs)
        dupVoxels = dupVoxelPairs(:,2);
        lgnROI(:, dupVoxels) = [];
        lgnROICoords(:, dupVoxels) = [];
    end
    nDupLoops = nDupLoops + 1;
end

%% Covert subscript coords to index coords for indexing into epi data
% Use co field of inplane scan to determine size of epi
lgnROICoordInds = sub2ind(size(INPLANE{1}.co{scan}),...
    lgnROICoords(1,:),lgnROICoords(2,:),lgnROICoords(3,:));

%% Read co, amp, and ph from loaded corAnal
voxelCorAnal.co = INPLANE{1}.co{scan}(lgnROICoordInds);
voxelCorAnal.amp = INPLANE{1}.amp{scan}(lgnROICoordInds);
voxelCorAnal.ph = INPLANE{1}.ph{scan}(lgnROICoordInds);

%% Mean tseries
roiMean = mean(lgnROI,2);

figure
plot(roiMean,'k','LineWidth',2)
xlabel('time (TRs)')
ylabel('Percent signal change')
title(['Mean time series - ' scanName])
if saveSummaryFigs
    print(gcf, '-dtiff', meanFigSavePath)
end

%% FFT, plot z-score
plotFlag = 0;
voxelNums = 1:size(lgnROI,2);
[voxelFFTRaw voxelFFT meanFFT data] = ...
        rd_plotVoxelFFT(lgnROI(:,voxelNums), INPLANE{1}, scan, plotFlag, voxelNums);
   
figure
hold on
scatter(voxelNums, data.zScore)
plot([voxelNums(1) voxelNums(end)], [2.5 2.5], 'r', 'LineWidth', 2)
xlim([voxelNums(1) voxelNums(end)])
xlabel('voxel number')
ylabel('fft z-score')
title(scanName)
if saveSummaryFigs
    print(gcf, '-dtiff', zFigSavePath)
end
    

%% Find voxels with z-scores > a threshold
zThreshs = [0 1 1.5 2 2.5 3 3.5];
for thresh = 1:length(zThreshs)
    z = zThreshs(thresh);
    w = data.zScore>z;
    zThresh(thresh).z = z;
    zThresh(thresh).voxNums = find(w);
    zThresh(thresh).zScores = data.zScore(w);
    zThresh(thresh).howMany = nnz(w);
end

%% Sort good voxels ...
% COME BACK

% goodThresh = 2.5;
% goodThreshIdx = find(zThreshs==goodThresh);
% goodVoxNums = zThresh(goodThreshIdx).voxNums;
% 
% goodVoxTSeries = lgnROI(:,goodVoxNums);

%% Save lgnROI data
if exist(savePath, 'file')
    error('A file with this name already exists ... File not saved.')
else
    save(savePath, 'lgnROI', 'lgnROICoords', 'lgnROICoordInds', 'voxelCorAnal', 'roiMean', 'voxelFFTRaw', 'voxelFFT', 'meanFFT', 'data', 'zThresh')
end

