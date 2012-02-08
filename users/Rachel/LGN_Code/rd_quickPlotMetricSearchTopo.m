% rd_quickPlotMetricSearchTopo.m

%% go
clear all

load mpMetricSearch0002

goodCostThresh = -1.5;
goodRuns = find(costVal<goodCostThresh);
goodCoefs = coefs(goodRuns,:); 
% coefNow = goodCoefs(26,:)

bestRun = find(costVal==min(costVal));
bestCoefs = coefs(bestRun,:); 
coefNow = bestCoefs(1,:)

rd_plotTopographicData