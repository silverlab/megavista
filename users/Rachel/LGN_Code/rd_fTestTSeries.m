function fStat = rd_fTestTSeries(hemi, scanDate, condName, nRuns)
%
% function fStat = rd_fTestTSeries(hemi, scanDate, condName, nRuns)
%
% hemi is hemifield (1=left, 2=right)
% scanDate is a string with the scan date, eg. '20110912'
% condName is a string, eg. 'MHigh'
% nRuns is the number of runs per condition
%
% Rachel Denison
% 12 September 2011

%% Setup
% hemi = 1; % 1 = left, 2 = right
% scanDate = '20110912';
% 
% condName = 'MHigh';
% nRuns = 3;

plotFigs = 0;

%% Load data
for iRun = 1:nRuns
    scanName = sprintf('Orig%s%d', condName, iRun);
    data(iRun) = load(sprintf('lgnROI%dData_%s_%s', hemi, scanName, scanDate));
end

%% Get tseries from each voxel
[nTRs nVox] = size(data(1).lgnROI);
tSeries = zeros(nTRs, nVox, nRuns);

for iRun = 1:nRuns
    tSeries(:,:,iRun) = data(iRun).lgnROI;
end

%% Calculate mean and variance across runs
tSeriesMean = mean(tSeries,3);
tSeriesVar = var(tSeries,0,3);

%% Calculate F statistic
varOfMeans = var(tSeriesMean,0,1); % for each voxel, across groups (here, TRs)
meanOfVars = mean(tSeriesVar,1); % for each voxel, across groups (here, TRs)

% F = variance between groups / variance within groups
fStat = varOfMeans./meanOfVars;

%% Plot histogram
if plotFigs
    figure
    hist(fStat)
    xlabel('f statistic')
    ylabel('number of voxels')
    title(sprintf('Hemi %d, %s - binned by TR', hemi, condName))
end

