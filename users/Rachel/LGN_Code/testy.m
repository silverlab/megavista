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




