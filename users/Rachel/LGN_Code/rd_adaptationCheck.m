% rd_adaptationCheck.m

% load figData

nFrames = 16;
ylims = [-4 4];

recodedTrials = rd_adaptationRecodeCond(figData.trials);
tSeries = figData.tSeries;
nVox = size(tSeries,2);
tSeriesPadded = [tSeries; nan(20,nVox)];

PMTrials = find(recodedTrials.cond==2);
blankMTrials = find(recodedTrials.cond==1);
MPTrials = find(recodedTrials.cond==4);
blankPTrials = find(recodedTrials.cond==3);
MblankTrials = find(recodedTrials.cond==5);
PblankTrials = find(recodedTrials.cond==6);

% PM
PMTrialTSeries = [];
for iTrial = 1:numel(PMTrials)
    frameStart = figData.trials.onsetFrames(PMTrials(iTrial));
    PMTrialTSeries(:,:,iTrial) = tSeriesPadded(frameStart:frameStart+nFrames-1,:);
end
PMTrialTSeriesTrialMean = nanmean(PMTrialTSeries,3);

f(1) = figure;
plot(PMTrialTSeriesTrialMean)
hold on
plot(mean(PMTrialTSeriesTrialMean,2),'k','LineWidth',2)
title('PM')
ylim(ylims)

% blankM
blankMTrialTSeries = [];
for iTrial = 1:numel(blankMTrials)
    frameStart = figData.trials.onsetFrames(blankMTrials(iTrial));
    blankMTrialTSeries(:,:,iTrial) = tSeriesPadded(frameStart:frameStart+nFrames-1,:);
end
blankMTrialTSeriesTrialMean = nanmean(blankMTrialTSeries,3);

f(2) = figure;
plot(blankMTrialTSeriesTrialMean)
hold on
plot(mean(blankMTrialTSeriesTrialMean,2),'k','LineWidth',2)
title('blankM')
ylim(ylims)

% MP
MPTrialTSeries = [];
for iTrial = 1:numel(MPTrials)
    frameStart = figData.trials.onsetFrames(MPTrials(iTrial));
    MPTrialTSeries(:,:,iTrial) = tSeriesPadded(frameStart:frameStart+nFrames-1,:);
end
MPTrialTSeriesTrialMean = nanmean(MPTrialTSeries,3);

f(3) = figure;
plot(MPTrialTSeriesTrialMean)
hold on
plot(mean(MPTrialTSeriesTrialMean,2),'k','LineWidth',2)
title('MP')
ylim(ylims)

% blankP
blankPTrialTSeries = [];
for iTrial = 1:numel(blankPTrials)
    frameStart = figData.trials.onsetFrames(blankPTrials(iTrial));
    blankPTrialTSeries(:,:,iTrial) = tSeriesPadded(frameStart:frameStart+nFrames-1,:);
end
blankPTrialTSeriesTrialMean = nanmean(blankPTrialTSeries,3);

f(4) = figure;
plot(blankPTrialTSeriesTrialMean)
hold on
plot(mean(blankPTrialTSeriesTrialMean,2),'k','LineWidth',2)
title('blankP')
ylim(ylims)

% Mblank
MblankTrialTSeries = [];
for iTrial = 1:numel(MblankTrials)
    frameStart = figData.trials.onsetFrames(MblankTrials(iTrial));
    MblankTrialTSeries(:,:,iTrial) = tSeriesPadded(frameStart:frameStart+nFrames-1,:);
end
MblankTrialTSeriesTrialMean = nanmean(MblankTrialTSeries,3);

f(5) = figure;
plot(MblankTrialTSeriesTrialMean)
hold on
plot(mean(MblankTrialTSeriesTrialMean,2),'k','LineWidth',2)
title('Mblank')
ylim(ylims)

% Pblank
PblankTrialTSeries = [];
for iTrial = 1:numel(PblankTrials)
    frameStart = figData.trials.onsetFrames(PblankTrials(iTrial));
    PblankTrialTSeries(:,:,iTrial) = tSeriesPadded(frameStart:frameStart+nFrames-1,:);
end
PblankTrialTSeriesTrialMean = nanmean(PblankTrialTSeries,3);

f(6) = figure;
plot(PblankTrialTSeriesTrialMean)
hold on
plot(mean(PblankTrialTSeriesTrialMean,2),'k','LineWidth',2)
title('Pblank')
ylim(ylims)

