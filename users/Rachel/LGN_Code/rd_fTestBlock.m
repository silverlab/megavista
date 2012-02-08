function fStat = rd_fTestBlock(hemi, scanDate, condName, hemoDelay)
%
% function fBlock = rd_fTestTSeries(hemi, scanDate, condName)
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
% scanDate = '20110913';
% 
% condName = 'MHigh';
% run = 1;
nTRsInBlock = 8; % CG 5; WC 8
% hemoDelay = 0; % in TRs
nCycles = 7; % CG 10; WC 7
blockTypes = [1 2];
blockOrder = repmat(blockTypes,1,nCycles);

plotFigs = 0;

%% Load data
% scanName = sprintf('Orig%s%d', condName, run)
scanName = sprintf('Avg%s', condName)
data = load(sprintf('lgnROI%dData_%s_%s', hemi, scanName, scanDate));

%% Get tseries from each voxel
[nTRs nVox] = size(data.lgnROI);
tSeries = data.lgnROI;

%% Calculate an average value for each block type and block rep in the run
for iBlockType = 1:length(blockTypes);
    blockPositions = find(blockOrder==iBlockType);
    for iBlockRep = 1:length(blockPositions)
        blockPos = blockPositions(iBlockRep);
        blockStartIdx = (blockPos-1)*nTRsInBlock + 1;
        blockEndIdx = blockStartIdx + nTRsInBlock - 1;

        blockIdxs = zeros(1,nTRs + hemoDelay); % re-initialize TR selector
        blockIdxs(blockStartIdx+hemoDelay:blockEndIdx+hemoDelay) = 1;
        blockIdxs = blockIdxs(1:nTRs); % truncate to length of time series
        
        blockTRVals = repmat(blockIdxs',1,nVox).*tSeries;
        blockVal = mean(blockTRVals,1); % mean for this block, for each voxel

        blockVals(iBlockType,:,iBlockRep) = blockVal;
    end
end

%% Calculate mean and variance across reps
blockMean = mean(blockVals,3);
blockVar = var(blockVals,0,3);

%% Calculate F statistic
varOfMeans = var(blockMean,0,1); % for each voxel, across groups (here, blocks)
meanOfVars = mean(blockVar,1); % for each voxel, across groups (here, blocks)

% F = variance between groups / variance within groups
fStat = varOfMeans./meanOfVars;

%% Plot histogram
if plotFigs
    figure
    hist(fStat)
    xlabel('f statistic')
    ylabel('number of voxels')
    title(sprintf('Hemi %d, %s - binned by block', hemi, condName))
end

