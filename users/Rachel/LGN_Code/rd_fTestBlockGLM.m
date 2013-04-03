function fStat = rd_fTestBlockGLM(tSeries, blockOrder, hemoDelay, blockTypes, figTitle)
%
% function fStat = rd_fTestBlockGLM(tSeriesFile, hemoDelay, blockTypes, figTitle)
%
% tSeriesFile contains the TR x vox tseries in vox_ts
% blockOrderFile contains the TR x vox tseries in condOrder
%
% Rachel Denison
% 7 October 2011

%% Setup
nTRsInBlock = 9; % CG 5; WC_20110731 8; WC_20110901 9
% hemoDelay = 0; % in TRs

plotFigs = 1;

%% Initializations
[nTRs nVox] = size(tSeries);
if isempty(blockTypes)
    blockTypes = unique(blockOrder);
end

%% Calculate an average value for each block type and block rep in the run
for iBlockType = 1:length(blockTypes);
    blockType = blockTypes(iBlockType);
    blockPositions = find(blockOrder==blockType);
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
    title(sprintf('%s, delay = %d', figTitle, hemoDelay))
end

