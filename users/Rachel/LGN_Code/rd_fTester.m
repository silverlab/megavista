function fStat = rd_fTester(tSeries, blockOrder, hemoDelay, blockTypes, plotFigs, figTitle)
%
% function fStat = rd_fTester(tSeries, blockOrder, hemoDelay, blockTypes, plotFigs, figTitle)
%
% tSeries is [nTRs x nVoxels]
% blockOrder is [1 x nBlocks] and gives the condition order, where each
%   condition is given a number (eg. [1 2 3 1 3 1 2 2])
% hemoDelay is the delay between the start of the block and the start of
%   the time series segment to be used for the F-test, in TRs
% blockTypes is the conditions to include in the F-test (eg. [2 3]). If 
%   empty, include all conditions. Optional - default is []. 
% plotFigs is 1 if you want to plot an F-stat histogram, 0 if not.
%   Optional - default is 1.
% figTitle is the title for your F-stat histogram, if you plot one.
%   Optional - default is [].
%
% Rachel Denison
% 13 Feb 2012

%% Supply missing optional arguments
if nargin < 4
    blockTypes = [];
end
if nargin < 5
    plotFigs = 1;
end
if nargin < 6
    figTitle = [];
end 

%% Initializations
[nTRs nVox] = size(tSeries);
nTRsInBlock = nTRs/numel(blockOrder);

if isempty(blockTypes)
    blockTypes = unique(blockOrder);
end
nBlockTypes = numel(blockTypes);

% find maximum number of block repetitions per condition
nBlockReps = zeros(1, nBlockTypes);
for iBlockType = 1:nBlockTypes;
    blockType = blockTypes(iBlockType);
    blockPositions = find(blockOrder==blockType);
    nBlockReps(iBlockType) = numel(blockPositions);
end

%% Calculate an average value for each block type and block rep in the run
blockVals = nan(nBlockTypes,nVox,max(nBlockReps));

for iBlockType = 1:nBlockTypes;
    blockType = blockTypes(iBlockType);
    blockPositions = find(blockOrder==blockType);
    
    for iBlockRep = 1:length(blockPositions)
        blockPos = blockPositions(iBlockRep);
        blockStartIdx = (blockPos-1)*nTRsInBlock + 1;
        blockEndIdx = blockStartIdx + nTRsInBlock - 1;

        blockIdxs = nan(1,nTRs + hemoDelay); % re-initialize TR selector
        blockIdxs(blockStartIdx+hemoDelay:blockEndIdx+hemoDelay) = 1;
        blockIdxs = blockIdxs(1:nTRs); % truncate to length of time series
        
        blockTRVals = repmat(blockIdxs',1,nVox).*tSeries;
        blockVal = nanmean(blockTRVals,1); % mean for this block, for each voxel

        blockVals(iBlockType,:,iBlockRep) = blockVal; % [blockTypes x voxels x reps]
    end
end

%% ANOVA
% for iVox = 1:nVox
%     voxVals = squeeze(blockVals(:,iVox,:));
%     [p table] = anova1(voxVals',[],'off'); % display off
%     anovaFStats(iVox) = table{2,5};
% end

%% Calculate mean and variance of each condition across reps
blockMean = nanmean(blockVals,3);
blockVar = nanvar(blockVals,0,3); 
overallMean = nansum(nansum(blockVals,3),1)/sum(nBlockReps);

%% Calculate F statistic
% varOfMeans = var(blockMean,0,1); % for each voxel, variance of within-condition means, across conditions
% meanOfVars = mean(blockVar,1); % for each voxel, mean of within-condition variance, across conditions

dfBetween = nBlockTypes-1;
SEBetween = (blockMean-repmat(overallMean,nBlockTypes,1)).^2;
weightedSEBetween = SEBetween.*repmat(nBlockReps',1,nVox);
SSEBetween = sum(weightedSEBetween)./dfBetween;

dfWithin = sum(nBlockReps) - nBlockTypes;
SEWithin = blockVar.*repmat((nBlockReps-1)',1,nVox); % undo N-1 normalization applied by var
SSEWithin = sum(SEWithin)./dfWithin;

% F = variance between groups / variance within groups
% fStat = varOfMeans./meanOfVars;
fStat = SSEBetween./SSEWithin;

%% Plot histogram
if plotFigs
    figure
    hist(fStat)
    xlabel('F statistic')
    ylabel('number of voxels')
    title(sprintf('%s, delay = %d', figTitle, hemoDelay))
end

