% rd_highLowAnalysis

%% Setup
hemi = 2;

saveFigs = 1;

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_highAndLowData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);

%% Data
load(loadPath)
condNames = {'low M', '(low) P', 'high M', '(high) P'};
betas = [l.betas' h.betas'];

%% Plots
f1 = figure;
bar(betas')
set(gca, 'XTickLabel', condNames)
title(sprintf('Hemi %d betas', hemi))

f2 = figure;
[f2h f2ax] = plotmatrix(betas);

f3 = figure;
condPairs = [1 3; 2 4; 1 2; 3 4];
xlims = [-2.5 2.5];
ylims = [-2.5 2.5];
for iPair = 1:size(condPairs,1)
    subplot(2,2,iPair)
    hold on
    condPair = condPairs(iPair,:);
    plot(betas(:,condPair(1)), betas(:,condPair(2)),'k.')
    plot(xlims, ylims, 'k')
    xlabel(condNames{condPair(1)})
    ylabel(condNames{condPair(2)})
    xlim(xlims)
    ylim(ylims)
    axis square
end
rd_supertitle(sprintf('Hemi %d betas', hemi))

%% Save figs
betasBarSavePath = sprintf('%s%s_%s_%s', fileBase, 'Bar', 'highLowBetas', datestr(now,'yyyymmdd'));
betasScatterSavePath = sprintf('%s%s_%s_%s', fileBase, 'Scatter', 'highLowBetas', datestr(now,'yyyymmdd'));

if saveFigs
    print(f1,'-djpeg',sprintf('figures/%s', betasBarSavePath));
    print(f3,'-djpeg',sprintf('figures/%s', betasScatterSavePath));
end

