function [voxelTSeries, numPts, epiROICoords, tSeries, tSerr] = rd_voxelTSeries(view, scan, ROINumbers)

% INPUTS:   view and scan as usual
%           ROINumbers is a list of numbers corresponding to which ROIs you
%               want to look at. So for ROI2 and ROI3, ROINumbers = [2 3].
%
% OUTPUTS:  voxelTSeries is a cell array with the time series for each
%               voxel in each ROI
%           numPts gives the number of voxels in an ROI whose values are
%               finite at each time point -- useful for averaging
%           tSeries is a cell array with the mean time series for each ROI
%           tSerr is a cell array with the mean of the squared time series
%               for each ROI

% Make a list of the available ROIs
nROIs=size(view.ROIs,2);
roiList=cell(1,nROIs);
for r=1:nROIs
    roiList{r}=view.ROIs(r).name;
end

% Find selected ROI indices
nSelectedROIs = length(ROINumbers);
for r=1:nSelectedROIs
    selectedROIName = sprintf('ROI%d', ROINumbers(r));
    ROIIdx = find(strcmp(roiList, selectedROIName));
    if numel(ROIIdx)==1
        selectedROIIdxs(r,1) = ROIIdx;
    else
        error(['Too many or too few ROIs with name ' selectedROIName])
    end
end

% Get selected ROI coords
for r=1:nSelectedROIs
    ROIIdx = selectedROIIdxs(r);
    ROIcoords{r} = view.ROIs(ROIIdx).coords;
end

% Get the mean and voxel-wise time series for each ROI
[tSeries, tSerr, voxelTSeries, numPts, epiROICoords] = rd_meanTSeries(view, scan, ROIcoords);