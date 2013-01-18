% rd_compareParameterMapsGroupAnalysis.m

% Should be in '/Volumes/Plata1/LGN/Group_Analyses/'

saveFigs = 1;

%% load and aggregate individual subject data
files = dir('crossSessionComparison*');

for iComp = 1:numel(files)
    data = load(files(iComp).name);
    subjects{iComp} = data.subjectID;
    roiNames{iComp} = data.roiName;
    
    mapValCorrs(iComp) = data.mapValCorr;
    corrConfs(:,iComp) = data.corrConf;
end

%% figure 
plotOrder = [1 4 7 8 2 5 3 6 9 10];

for iComp = 1:numel(mapValCorrs)
    labels{iComp} = sprintf('%s-%s', subjects{plotOrder(iComp)}, ...
        roiNames{plotOrder(iComp)});
end

f1 = figure;
hold on
bar(1:numel(mapValCorrs), mapValCorrs(plotOrder))
errorbar(1:numel(mapValCorrs), mapValCorrs(plotOrder), ...
    mapValCorrs(plotOrder)-corrConfs(1,plotOrder), ...
    corrConfs(2,plotOrder)-mapValCorrs(plotOrder), ...
    'r','LineWidth',2,'LineStyle','None')
xlim([0 numel(mapValCorrs)+1])
set(gca,'XTick', 1:numel(mapValCorrs))
set(gca,'XTickLabel',labels)
ylabel('correlation with 95% confidence interval')

%% save fig
if saveFigs
    print(f1,'-djpeg',...
        sprintf('figures/groupCrossSessionComparison_betaM-P_correlation_%s',...
        datestr(now,'yyyymmdd')));
end

