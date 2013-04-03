% rd_compareScansTSDiff.m

epiNumbers = 1:12;
nScans = length(epiNumbers);

for iScan = 1:nScans
    scan = epiNumbers(iScan);
    load(sprintf('epi%02d/timediff.mat',scan))
    tds(:,iScan) = td;
end

tdsMeans = mean(tds);

for iScan = 1:nScans
    tdsScaled(:,iScan) = tds(:,iScan)./tdsMeans(iScan)-1;
end

tdScanMean = mean(tds,2);
tdScaledScanMean = mean(tdsScaled,2);

figure
subplot(2,1,1)
hold on
plot(tds)
plot(tdScanMean,'-k','LineWidth',2)
title('Raw TD mean')
subplot(2,1,2)
hold on
plot(tdsScaled)
plot(tdScaledScanMean,'-k','LineWidth',2)
title('Scaled TD mean')