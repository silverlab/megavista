function [subTSeries, subIndices] = getTSeriesROI(vw, roiCoords, preserveCoords)
% getTSeriesROI - Extract subTSeries from vw.tSeries for given ROI.
%
%  [subTSeries, subIndices] = getTSeriesROI(vw, roiCoords, preserveCoords)
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
% the columns in roiCoords. [Default 0]. If 0, will remove tSeries columns
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
% are many cases where you want to maintain the coords. 
if ~exist('preserveCoords','var') || isempty(preserveCoords)
    preserveCoords = 0;
end

if isempty(roiCoords) || isempty(vw.tSeries)
    subTSeries = [];
	return
end
switch vw.viewType
	case 'Inplane'
		scan = vw.tSeriesScan;

		% Need to divide the roiCoords by the upSample factor because the
		% data are no longer interpolated to the inplane size.
		%
		% ras, 09/2008: removed the scan dependency on this. Right now,
		% if there's ever a session where different scans have
		% different resolutions, it will take a substantial workaround
		% to fix. Here, we simplify by assuming that the up sample
		% factor is the same across scans.
		rsFactor = upSampleFactor(vw);
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

		inSlice = roiCoords(3, :) == vw.tSeriesSlice;
		subIndices = coords2Indices(roiCoords(1:2, inSlice), viewGet(vw, 'sliceDims', scan));

		% pull out the tSeries for included pixels
		subTSeries = vw.tSeries(:, subIndices);

	case {'Gray' 'Volume'}
		% ensure time series are loaded
		if isempty(vw.tSeries)
			vw = percentTSeries(vw, getCurScan(vw), 1);
		end
		
		[inter, roiIndices, subIndices] = intersectCols(roiCoords, vw.coords);
		subTSeries = vw.tSeries(:,subIndices);		
		
		if preserveCoords==1    
			% enforce subTSeries size == ROI coords size
			% ras 09/07: now preserves coord order, as well as size
			% (slower than previous algorithm, but more robust)
			nVoxels = size(roiCoords, 2);
			nFrames = size(vw.tSeries, 1);
			subTSeries = repmat(NaN, [nFrames nVoxels]);
			subIndices = repmat(NaN, [1 nVoxels]);
			for v = 1:size(roiCoords, 2)
				I = find( vw.coords(1,:) == roiCoords(1,v) & ...
						  vw.coords(2,:) == roiCoords(2,v) & ...
						  vw.coords(3,:) == roiCoords(3,v) );
				
				if ~isempty(I)
					% we index I by (1), because it's actually possible for
					% it to have >1 entry. That is, it's possible for two
					% voxels in vw.coords to point to the same place!
					% That's weird, but probably because one voxel is
					% included in both the left and right hemisphere
					% segmentations. Perhaps we should also warn the user,
					% because it might mean a segmentation issue?
					subTSeries(:,v) = vw.tSeries(:,I(1));
					subIndices(v) = I(1);
				end
			end
		end

	case 'Flat'
		% choose sub-roiCoords from the currently loaded slice
        subIndices = find(roiCoords(3, :)==vw.tSeriesSlice);

        subCoords = roiCoords(:, subIndices);
        ind = sub2ind(size(vw.anat(:,:,vw.tSeriesSlice)),...
            subCoords(1, :), subCoords(2, :));

        subTSeries = vw.tSeries(:, ind);
            
end

return
