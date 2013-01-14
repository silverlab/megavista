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


% calculating coherence between time series
x = sin(1:30);
y = sin((1:30)-2);

[Pxx f] = pwelch(x,[],[],30,[]);
[Pyy f] = pwelch(y,[],[],30,[]);
Pxy = cpsd(x,y,[],[],30,[]);
cohxy = (abs(Pxy).^2)./(Pxx.*Pyy); % from Sun paper

figure
plot(f,Pxx)
plot(f,Pyy)
plot(f, cohxy, 'r')
plot(f, abs(Pxy).^2, 'g')


% excluding runs from indiv scan data
oldRunsString = '1-7'; % RD '1-12'
newRuns = [1 3:7]; % RD 2:12
newRunsString = '1.3-7'; % RD '2-12'
for hemi = 1:2
    for analysisName = {'multiVoxel','timeCourse'}
        origFile = sprintf('lgnROI%d_indivScanData_%s_20120417.mat', hemi, analysisName{1});
        safeFile = sprintf('OLD_lgnROI%d_indivScanData_%s_20120417_runs%s.mat',...
            hemi, analysisName{1}, oldRunsString);
        newFile = sprintf('lgnROI%d_indivScanData_%s_20130113_runs%s.mat',...
            hemi, analysisName{1}, newRunsString);
        
        load(origFile)
        system(sprintf('mv %s %s', origFile, safeFile))
        uiData = uiData(newRuns);
        save(newFile, 'uiData')
    end
end
