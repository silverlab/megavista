% trying things out

vw = INPLANE{1};
scan = 1; 
ROIcoords = INPLANE{1}.ROIs(1).coords;
getRawData = 1;

[tSeries, tSerr, voxelTSeries, numPts, epiROICoords] = ...
    rd_meanTSeries(INPLANE{1}, 1, INPLANE{1}.ROIs(1).coords);


% plot mean time series raw (menu callback)
plotMeanTSeries(INPLANE{1}, viewGet(INPLANE{1}, 'current scan'), [], true);getPlottedData;

tSeriesRaw = meanTSeries(vw,scan,ROIcoords, getRawData);
