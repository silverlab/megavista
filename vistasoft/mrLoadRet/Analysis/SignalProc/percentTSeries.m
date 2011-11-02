function view = percentTSeries(view, scanNum, sliceNum, detrend, inhomoCorrection, temporalNormalization, noMeanRemove)
%
% view = percentTSeries(view, scanNum, sliceNum, [detrend], [inhomoCorrection], [temporalNormalization], [noMeanRemove])
%
% Checks the tSeriesScan and tSeriesSlice slots to see if the
% desired tSeries is already loaded. If so, don't do anything.
% Otherwise:
% 1) loads tSeries corresponding to scanNum/sliceNum.
% 2) removes the DC and baseline trend of a tSeries.
% 3) sets:
%    view.tSeries = resulting percent tSeries
%    view.tSeriesScan = scanNum
%    view.tSeriesSlice = sliceNum
%
% Options for how to remove the baseline, depending on
% the value of detrend
%   0 no trend removal
%   1 highpass trend removal
%   2 quadratic removal
%   -1 linear trend removal
% Default: detrend = detrendFlag(view,scanNum)
%
% Options for how to compensate for distance from the coil, depending
% on the value of inhomoCorrection
%   0 do nothing
%   1 divide by the mean, independently at each voxel
%   2 divide by null condition
%   3 divide by anything you like, e.g., robust estimate of intensity inhomogeneity
% For inhomoCorrection=3, you must compute the spatial gradient
% (from the Analysis menu) or load a previously computed spatial
% gradient (from the File/Parameter Map menu).

% EDIT HISTORY:
% djh, 1/22/98
% arw, 12/05/99 Added option to remove quadratic function
% dbr, 8/1/00 Added high-pass baseline removal option
% dbr, 11/16/00 Made high-pass trend removal the default (detrendFlag = 1).
%               Linear trend removal is now detrendFlag = -1.
% djh, 11/00  Added option of dividing by spatialGradient
%             (estimate of intensity inhomogeneity) instead
%             of dividing by mean at each pixel.
% djh, 2/2001 Updated to mrLoadRet-3.0
%             Detrending is now done in detrendTSeries.m
%             This function now sets view.tSeries (loadtSeries used to do this)
% djh, 9/28/2001 Subtract the mean (again) near the end to make sure it's zero
%             Otherwise, it messes up the correlation map.
% djh, 7/12/2002 Changed the options for inhomogeneity correction
%             Used to have only two options (0: divide by mean; 1: divide by robust est)
%             In the current code, current option 1 is the same as what used to be 0
%             and current option 2 is what used to be.
% dhb, 6/3/2003  Comment out code that checks slice and scan numbers and
%             assumes tSeries is cached if they match passed values.  This
%             check did not seem to be bulletproof.
% ras, 3/8/2007		reverted some changes suggested by Mark Schira about
%			  making singles. I agree to use single precision, but will
%			  make the change in loadtSeries and savetSeries, so that this
%			  code doesn't modify the input data type.

if notDefined('detrend'),               detrend               = detrendFlag(view,scanNum); end
if notDefined('inhomoCorrection'),      inhomoCorrection      = inhomoCorrectionFlag(view,scanNum); end
if notDefined('temporalNormalization'), temporalNormalization = 0; end
if notDefined('noMeanRemove'),          noMeanRemove          = 0; end


% load tSeries
tSeries = loadtSeries(view, scanNum, sliceNum);

% also, if the tSeries is empty, return w/o erroring
if isempty(tSeries)
	view.tSeries      = [];
	view.tSeriesScan  = scanNum;
	view.tSeriesSlice = sliceNum;
	return
end

nFrames = size(tSeries,1);

% Added by ARW
if (temporalNormalization)
	disp('Temporal normalization to first frame');
	tSeries=doTemporalNormalization(tSeries);
end

% Make the mean of all other frames the same as this.
% Divide by either the mean or the spatial gradient
%
switch inhomoCorrection
	case 0
		ptSeries = tSeries;
	case 1
		dc = nanmean(tSeries);
		dc(dc==0 | isnan(dc)) = Inf;  % prevents divide-by-zero warnings
		ptSeries = tSeries ./ (ones(nFrames,1) * dc);
	case 2
		myErrorDlg('Inhomogeneity correction by null condition not yet implement');
	case 3
		if ~isfield(view, 'spatialGrad') || isempty(view.spatialGrad)
			try
				view = loadSpatialGradient(view);
				updateGlobal(view); % make sure it stays loaded
			catch                
				myErrorDlg(['No spatial gradient map loaded. Either load '...
					'the spatial gradient map from File menu or edit ' ...
					'dataTypes to set inhomoCorrect = 0 or 1']);
			end
		end
		gradientImg = view.spatialGrad{scanNum}(:,:,sliceNum);
		dc = gradientImg(:)';
		ptSeries = tSeries./(ones(nFrames,1)*dc);
	otherwise
		myErrorDlg(['Invalid option for inhomogeneity correction: ',num2str(inhomoCorrection)]);
end

% Remove trend
%
if detrend
	ptSeries = detrendTSeries(ptSeries,detrend,detrendFrames(view,scanNum));
end

% Subtract the mean
% Used to just subtract 1 under the assumption that we had already divided by
% the mean, but now with the spatialGrad option the mean may not be exactly 1.
%
if noMeanRemove==0
	ptSeries = ptSeries - ones(nFrames,1)*mean(ptSeries);
	% Multiply by 100 to get percent
	%
	ptSeries = 100*ptSeries;
end

% Set fields in view
view.tSeries      = ptSeries;
view.tSeriesScan  = scanNum;
view.tSeriesSlice = sliceNum;


return



