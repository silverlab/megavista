% rd_plotDetrendedTSeries.m

% set tSeries to a tseries already in the workspace
tSeries = inplaneRawROIMultiScanTSeries(:,19);
% tSeries = inplaneRawROI(:,19,2);
smoothFrames = 10;

tSeries_m = tSeries/mean(tSeries); % divided by mean
tSeries_mb = removeBaseline2_COPY(tSeries_m, smoothFrames); % and baselined

% Subtract the mean (from percentTSeries)
% Used to just subtract 1 under the assumption that we had already divided by
% the mean, but now with the spatialGrad option the mean may not be exactly 1.
ptSeries = tSeries_mb - ones(length(tSeries_mb),1)*mean(tSeries_mb);
ptSeries = 100*ptSeries; % Multiply by 100 to get percent


figure
subplot(3,1,1)
plot(tSeries)
ylabel('Signal')
title('Raw')
subplot(3,1,2)
plot(tSeries_m)
ylabel('Scaled signal')
title('Scaled')
subplot(3,1,3)
plot(ptSeries)
ylabel('% signal change')
title('Detrended')