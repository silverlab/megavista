function [subTSeries, subIndices, subEpiROICoords] = rd_getTSeriesROI(view, roiCoords, preserveCoords)
% getTSeriesROI - Extract subTSeries from view.tSeries for given ROI.
%
%  [subTSeries, subIndices] = getTSeriesROI(view, roiCoords, preserveCoords)
%
% This only returns the tSeries values from the currently loaded slice and
% scan.  Perhaps it should mention that fact in its name?  Or maybe it
% should go through all the slices.  Probably we should put this
% functionality into viewGet() and have it work for all slices.
%
% subIndices: indices of those columns
% within the relevant tSeries matrix which correspond
% to the returned subTSeries.
%
% preserveCoords: flag to make the columns in subTSeries correspond to
% the columns in roiCoords. [Default 1]. If 0, will remove tSeries columns
% from redundant coords, but also shuffle the order.
%
% djh,  2/2001
% ras,  1/2004
% - fixed a bug for the case where the upSampleFactor is different in
% different directions.
% ras,  10/2004
% - commented out the part where it errors
% if a tSeries spans slices / hemis. Why not?
% (plus,  it's crucial for an acr-levels analysis)
% ras,  04/05
% - returns coordinates from which each voxel was taken
% sod 01/2006: modification to use only unique coordinates
% ras 07/2006: need to use a flag for getting rid of coords: there
% are many cases where you want to maintain the coords. Actually, I think
% you don't want to do this here at all, since it causes your output 
% (columns in tSeries) to be out of sync with your inputs (ROI coords);
% e.g. the event-related code gets rid of both together if you want to
% remove redundant coords (this breaks it). Also, the unique
% function used to remove duplicates scrambles the order of tSeries
% with respect to coords: this can lead to further issues.
% So, I'm setting the default preserveCoords value to 1.
if ~exist('preserveCoords','var') | isempty(preserveCoords)
    preserveCoords = 1;
end
if isempty(roiCoords) | isempty(view.tSeries)
    subTSeries = [];
else
    switch view.viewType
        case 'Inplane'
            scan = view.tSeriesScan;
            
            % Need to divide the roiCoords by the upSample factor because the
            % data are no longer interpolated to the inplane size.
            rsFactor = upSampleFactor(view, scan);
            if length(rsFactor)==1
                roiCoords(1:2,:) = round(roiCoords(1:2,:)/rsFactor(1));
            else
                roiCoords(1,:) = round(roiCoords(1,:)/rsFactor(1));
                roiCoords(2,:) = round(roiCoords(2,:)/rsFactor(2));
            end
            
            if preserveCoords==0
                % no need to keep duplicate coords 
                roiCoords = unique(roiCoords', 'rows')';
            end
            
            inSlice = find(roiCoords(3, :) == view.tSeriesSlice);
            subIndices = coords2Indices(roiCoords(1:2, inSlice), sliceDims(view, scan));
            % pull out the tSeries for included pixels
            subTSeries = view.tSeries(:, subIndices);
            % also keep track of the corresponding ROI coords
            subEpiROICoords = roiCoords(:, inSlice);
        case {'Gray' 'Volume'}
            [inter, roiIndices, subIndices] = intersectCols(roiCoords, view.coords);
            subTSeries = view.tSeries(:,subIndices);
            
            if preserveCoords==1    
                % enforce subTSeries size == ROI coords size
                nVoxels = size(roiCoords, 2);
                nFrames = size(view.tSeries, 1);
                subTSeries = repmat(NaN, [nFrames nVoxels]);
                subTSeries(:,roiIndices) = view.tSeries(:,subIndices);
            end
                
        case 'Flat'
            % choose sub-roiCoords from the currently loaded slice
            subInd = find(roiCoords(3, :)==view.tSeriesSlice);
            subCoords = roiCoords(:, subInd);
            ind = sub2ind(size(view.indices), subCoords(1, :), subCoords(2, :), subCoords(3, :));
            subIndices = view.indices(ind);
            subIndices = subIndices(subIndices>0); % ignore non-measured points
            % this assumes the view's tSeries will only
            % be for the current slice -- if the way tSeries
            % are processed is updated (in percentTSeries,  loadtSeries, 
            % etc),  make sure to update this:
            subTSeries = view.tSeries(:, subIndices);
    end
end
return
% % Older:
%         h=view.tSeriesSlice;
%         if find(h ~= roiCoords(3, :))
%             myErrorDlg('getTSeriesROI: roiCoords must all be from the same hemisphere.');
%         end
