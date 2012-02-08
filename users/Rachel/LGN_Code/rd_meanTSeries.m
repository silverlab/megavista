function [tSeries, tSerr, voxelTSeries, numPts, epiROICoords] = rd_meanTSeries(view,scanNum,ROIcoords)
% Computes the mean tSeries, averaged over ROIcoords, for scanNum.
%
%   tSeries = meanTSeries(view,scanNum,[ROIcoords])
%
% scanNum: scan number
% ROIcoords can be either:
%    3xN array of (y,x,z) coords
%    cell array of ROIcoords arrays
%    if nothing passed, default is to extract ROIcoords for all ROIs
%
% djh, 7/98
% djh, 2/2001
% - updated to mrLoadRet-3.0
% - updated to work for gray and flat views
% bw/ab 6/2003
% - wrote getSlicesROI, ROIcoords2cellArray and inserted here so
%   we could use those routines in other places, too.
% Ress, 4/05 One fix and a new feature:
% Fix: Added code to properly ignore bad-flagged (NaN) values when taking the
% mean. Feature: Now returns spatial SEM as an optional second output
% argument; note that this estimate needs to be scaled up by a voxel-size
% dependent spatial correlation factor

% At this point, we should check whether the tSeries exists for the
% relevant view type (Inplane, Gray, or Flat).  If the tSeries data do not
% exist for this view type, then we want to transform the ROI data into the
% Inplane format (where there should always be a tSeries) and plot that
% tSeries.

% Make sure the input is in the right format
if ~exist('ROIcoords','var'), ROIcoords = [];   end
ROIcoords = ROIcoords2cellArray(view,ROIcoords);

% Find the slice indices for this collection of ROIs
sliceInds = getSlicesROI(view,ROIcoords);

nROIs = length(ROIcoords);

tSeries = cell(1,nROIs);
tSerr = cell(1, nROIs);

nFrames = numFrames(view,scanNum);
detrend = detrendFlag(view,scanNum);
% detrend = 0;
smoothFrames = detrendFrames(view,scanNum); 

% Take first pass through ROIs to see which slices to load
switch view.viewType
case {'Inplane' 'Flat'}
    sliceInds = [];
    for r=1:nROIs
        if isempty(ROIcoords{r})
            disp('MeanTSeries: ignoring empty ROI in this slice')
        else
            sliceInds = [sliceInds, ROIcoords{r}(3,:)];
        end
    end
    sliceInds = unique(sliceInds);
case {'Gray' 'Volume'}
    sliceInds = 1;
otherwise
    myErrorDlg('meanTSeries: Only for Inplane, Gray, or Flat views.');
end


% Loop through slices
for iSlice = 1:length(sliceInds);
    slice = sliceInds(iSlice);
    % Load tSeries & divide by mean, but don't detrend yet.
    % Otherwise, detrending the entire tSeries is much slower. DJH
    view = percentTSeries(view,scanNum,slice,0);
    
    for r=1:nROIs
        % Extract time-series
        [subtSeries, subIndices, subEpiROICoords] = rd_getTSeriesROI(view,ROIcoords{r});
        if ~isempty(subtSeries)
            % Detrend now (faster to do it now after extracting subtSeries for a small subset of the voxels)
            subtSeries = detrendTSeries(subtSeries,detrend,smoothFrames);
            % Add 'em up
            if isempty(tSeries{r})
                numPts{r} = sum(isfinite(subtSeries), 2);
                subtSeries(~isfinite(subtSeries)) = 0;
                tSerr{r} = sum(subtSeries.^2, 2);
                tSeries{r} = sum(subtSeries, 2);
                voxelTSeries{r} = subtSeries;
                epiROICoords{r} = subEpiROICoords;
            else
                numPts{r} = numPts{r} + sum(isfinite(subtSeries), 2);
                subtSeries(~isfinite(subtSeries)) = 0;
                tSerr{r} = tSerr{r} + sum(subtSeries.^2, 2);
                tSeries{r} = tSeries{r} + sum(subtSeries,2);
                voxelTSeries{r} = [voxelTSeries{r} subtSeries];
                epiROICoords{r} = [epiROICoords{r} subEpiROICoords];
            end
        end
    end
end

% Final pass through ROIs to turn sum into mean
for r=1:nROIs
    if isempty(numPts{r})
        tSeries{r} = zeros(nFrames,1);
        tSerr{r} = zeros(nFrames, 1);
    else
        tSeries{r} = tSeries{r} ./ numPts{r};
        tSerr{r} = sqrt((tSerr{r} ./ numPts{r}.^2) - tSeries{r}.^2./numPts{r});
    end
end

if (nROIs==1)
    tSeries = tSeries{1};
    tSerr = tSerr{1};
end

% Clean up (because didn't detrend the whole tSeries properly)
view.tSeries=[];
view.tSeriesScan=NaN;
view.tSeriesSlice=NaN;

return;

