% rd_fTest.m

%% Setup
hemi = 2;
scanDate = '20111026';

condNames = {'MLow','MHigh','PLow','PHigh'};
nConditions = length(condNames);
% nRuns = 3;

hemoDelays = 3; % 0:3
nDelays = length(hemoDelays);

saveFigs = 1;

%% File I/O
figFileBase = sprintf('lgnROI%dHist_%s', hemi, scanDate);
% fTRFigSavePath = sprintf('figures/%s_fTR%s', figFileBase, datestr(now,'yyyymmdd'));
fBlockFigSavePath = sprintf('figures/%s_fBlock%s', figFileBase, datestr(now,'yyyymmdd'));

%% Calculate f statistic for each voxel in each condition
% %% bin by TR
% for iCond = 1:nConditions
%     condName = condNames{iCond};
%     fTR(:,iCond) = rd_fTestTSeries(hemi, scanDate, condName, nRuns);
% end
% 
% fTRMean = mean(fTR);
% fTRMax = max(fTR);

%% bin by block
for iDelay = 1:nDelays
    hemoDelay = hemoDelays(iDelay);
    
    for iCond = 1:nConditions
        condName = condNames{iCond};
        fBlock(:,iCond) = rd_fTestBlock(hemi, scanDate, condName, hemoDelay);
    end

    fBlockMean = mean(fBlock);
    fBlockMax = max(fBlock);

    fprintf('\nhemoDelay = %d:\n', hemoDelay)
    disp([fBlockMean; fBlockMax])
end

%% Plot f hists
%% bin by TR
% figure
% for iCond = 1:nConditions
%     subplot(2,2,iCond)
%     hold on
%     hist(fTR(:,iCond))
%     ylims = get(gca, 'ylim');
%     plot([fTRMean(iCond) fTRMean(iCond)],ylims,'r','LineWidth',2)
%     
%     xlabel('f statistic')
%     ylabel('number of voxels')
%     title(sprintf('Hemi %d, %s - binned by TR', hemi, condNames{iCond}))
% end
% if saveFigs
%     print(gcf, '-dtiff', fTRFigSavePath)
% end

%% bin by block
figure
for iCond = 1:nConditions
    subplot(2,2,iCond)
    hold on
    hist(fBlock(:,iCond))
    ylims = get(gca, 'ylim');
    plot([fBlockMean(iCond) fBlockMean(iCond)],ylims,'r','LineWidth',2)
    
    xlabel('f statistic')
    ylabel('number of voxels')
    title(sprintf('Hemi %d, delay %d, %s - binned by block', ...
        hemi, hemoDelay, condNames{iCond}))
end
if saveFigs
    print(gcf, '-dtiff', fBlockFigSavePath)
end

