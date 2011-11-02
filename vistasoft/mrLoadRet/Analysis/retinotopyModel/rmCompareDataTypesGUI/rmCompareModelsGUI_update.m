function M = rmCompareModelsGUI_update(M);
% Refresh the GUI for comparing pRF estimates across data types.
%
% M = rmCompareModelsGUI_update([M=get from GUI]);
%
%
% ras, 02/2009.
if notDefined('M')
	M = get(gcf, 'UserData');
end

% get a vector of time points for the model -- will be used for plotting
TR = M.params.stim(1).framePeriod;
t = [0:size(M.tSeries{1}, 1)-1]' .* TR;

v = M.voxel;
X = M.params.analysis.X;
Y = M.params.analysis.Y; 

%% loop across models
for m = 1:M.nModels
	%% get the tSeries / pRF params for the selected voxel
	for f = {'tSeries' 'x0' 'y0' 'sigma' 'pol' 'ecc'}
		eval( sprintf('%s = M.%s{m}(:,v);', f{1}, f{1}) );
	end
	beta = M.beta{m}(v,:);

	%% create a vector of params
	% (Todo: make this work for different model types)
	rfParams = [x0 y0 sigma 0 sigma 0];
	
	% modify the params if specified by the GUI
	rfParams = movePRF(M, rfParams, v);
	x0 = rfParams(1);
	y0 = rfParams(2);
	sigma = rfParams(3);
	
	%% get pRF values as column vectors
	RFvals = rmPlotGUI_makeRFs(M.modelName, rfParams, X, Y);
	
	%% get the pRF image and predicted time series
	% make predictions (add trends)
	if isequal( get(M.ui.maxPredictionMethod, 'Checked'), 'on' )
		% use alternate method: 'max' function over the stimulus location
		RF = repmat(RFvals(:)', [length(t) 1]);
		pred = max( M.params.analysis.allstimimages .* RF, [], 2 );
	else
		% standard method: simple multiply/sum over pixels
		pred = M.params.analysis.allstimimages * RFvals;
	end
	
	% add trends
	[trends, ntrends, dcid] = rmMakeTrends(M.params, 0);
	pred = [pred trends(:,1)] * beta(:,1:2)';	

	% occasionally the beta values will be way out of whack --
	% like, an order of magnitude too large. Not quite sure the
	% ultimate cause, but for now, I auto-scale the predictor to
	% have the same max as the time series. As long as I make clear
	% that the prediction units are arbitrary, this should be ok.
% 	pred = pred .* (max(tSeries) ./ max(pred(:)));
	[T df RSS B] = rmGLM(tSeries, [pred trends(:,1)], [1 -1]);
	pred = B(1)*pred + B(2);

	% compute variance explained for this voxel
	R = corrcoef([pred tSeries]);
	varexp = 100 * R(2) .^ 2;
	
	%% plot results
	% time series 
	axes(M.ui.tSeriesAxes(m));  cla;  hold on
	plot(t, tSeries, t, pred);  hold on
	axis tight
	setLineColors({'k' 'b'});
	setLineStyles({'1.5-' '1.5-'});
	line([t(1) t(end)], [0 0], 'LineWidth', 1.5, 'LineStyle', ':', 'Color', 'r');
	if m==M.nModels
		axis on
		set(gca, 'Box', 'off');
		xlabel('Time (s)', 'FontSize', 12);
		ylabel('% Signal', 'FontSize', 12);
	else
		axis off;
	end
	title( sprintf('%s: %2.0f%% variance explained', M.dtList{m}, varexp) );

	% for the time series plot, show the time point on the time series axes
	if get(M.ui.overlayStimCheck, 'Value')==1
		% delete the last line
		delete( findobj('Parent', gca, 'Tag', 'CurStimPoint') );
		
		% get the current time point
		TR = M.params.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans	
		tStim = get(M.ui.time.sliderHandle, 'Value') * TR;
		
		% draw the new line
		AX = axis;
		hold on
		hLine = line([tStim tStim], AX(3:4), 'LineWidth', 2, ...
					 'LineStyle', '--', 'Color', 'm');
		set(hLine, 'Tag', 'CurStimPoint');
	end
	
	% pRF 
	axes(M.ui.rfAxes(m));  cla;  hold on
	showPRF(M, RFvals, gca);
	txt = sprintf('(x, y, \\sigma) = (%.1f, %.1f, %.1f)', x0, y0, sigma);
	txt = sprintf('%s\n(pol, ecc) = (%.1f, %.1f)', txt, pol * (180/pi), ecc);
	title(txt);	

end  

% normalize the time series axes 
normAxes( M.ui.tSeriesAxes );


%% set information fields
% voxel coords
set(M.ui.coordsText, 'String', ['Coords: ', num2str( [M.roi.coords(:,v)]')]);

% update the previous voxel
M.prevVoxel = M.voxel;
set(M.fig, 'UserData', M);

return
% ---------------------------------------------------------------



% ---------------------------------------------------------------
function rfParams = movePRF(M, rfParams, voxel)
% Subroutine to manually alter the pRF center for visualizing other fits.
% The stored model is not altered. 
%
% This is constrained right now to the circular Gaussian case. This is
% mainly because of simple contraints of space in the GUI window for adding
% more sliders. I think a better long-term solution is to break off a
% separate subfunction, expressly designed for editing a single pRF, which
% would lack the voxel slider, and a number of other options, but would
% have sliders for sigma major/minor, theta (angle b/w axes), etc. (ras)

%% has the selected voxel changed?
if voxel ~= M.prevVoxel 
	% let's update the 'pRF adjust params' sliders to match the new voxel.
	% (we'll wait until the user adjusts one of the sliders to modify
	% rfParams.)
	mrvSliderSet(M.ui.moveX, 'Value', rfParams(1));
	mrvSliderSet(M.ui.moveY, 'Value', rfParams(2));
	mrvSliderSet(M.ui.moveSigma, 'Value', rfParams(3));
	set(M.ui.moveToPreset, 'Value', 1);	
end

%% if we got here, we haven't changed the voxel: 
% we can adjust the rfParams, *if* the option is selected...

% test whether the 'adjust PRF' option is selected
if get(M.ui.movePRF, 'Value')==1
	% either manually move the pRF according to slider values...
	mrvSliderSet(M.ui.moveX, 'Visible', 'on');
    mrvSliderSet(M.ui.moveY, 'Visible', 'on');
	mrvSliderSet(M.ui.moveSigma, 'Visible', 'on');
	set( M.ui.moveToPreset, 'Visible', 'on' )	

	rfParams(1) = get(M.ui.moveX.sliderHandle, 'Value');
    rfParams(2) = get(M.ui.moveY.sliderHandle, 'Value');
	rfParams(3) = get(M.ui.moveSigma.sliderHandle, 'Value');
	rfParams(5) = rfParams(3);   % circular case
	
else
	% ... or use stored values  (and keep the sliders hidden)
    mrvSliderSet(M.ui.moveX, 'Visible', 'off');
    mrvSliderSet(M.ui.moveY, 'Visible', 'off');
    mrvSliderSet(M.ui.moveSigma, 'Visible', 'off');
	set(M.ui.moveToPreset, 'Visible', 'off');
	set(M.ui.moveToPreset, 'Value', 1);	
end

return
% ---------------------------------------------------------------



% ---------------------------------------------------------------
function showPRF(M, RFvals, axs);
%% show the pRF in the axes (axs), superimposing the stimuli if that option
%% is selected.
rescaleToPeak = isequal( get(M.ui.peakCheck, 'Checked'), 'on' );
if get(M.ui.overlayStimCheck, 'Value')==0
	%% show the RF only, don't overlay the stimulus image
	if rescaleToPeak==0, 
		peak = [];
	else
		TR = M.params.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans
		peak = rfParams(4) .* M.params.analysis.sampleRate^2 .*  TR;
	end;

	rfPlot(M.params, RFvals, axs, peak);

	% make sure the time slider is not visible
	mrvSliderSet(M.ui.time, 'Visible', 'off');
else
	%% overlay the stimulus image on the RF
	TR = M.params.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans	
	t = get(M.ui.time.sliderHandle, 'Value') * TR;
		
	% get the stimulus image for this frame
	f = round(t / M.params.stim(1).framePeriod); % MR frame
	if f < 1 || f > size(M.params.analysis.allstimimages, 1)
		warning('Can''t visualize stimulus: selected time point outside scan range.')
		return
	end
	[stimImage RF] = getCurStimImage(M, f, RFvals);	
	
	% overlay and siplay
	axes(axs); cla
% 	RF_img(:,:,1) = RF;
% 	RF_img(:,:,2) = 1-RF;
% 	RF_img(:,:,3) = stimImage;
	RF_img(:,:,1) = stimImage;
	RF_img(:,:,2) = RF;
	RF_img(:,:,3) = RF;

    [x,y] = prfSamplingGrid(M.params);
    x = x(:); y = y(:);
    imagesc(x, -y, RF_img); hold on;
    plot([min(x) max(x)], [0 0], 'k-');
    plot( [0 0], [min(y) max(y)], 'k-');
    
    axis image xy;
    ylabel('y (deg)');
    xlabel('x (deg)');
	
	% make sure the time slider is visible
	mrvSliderSet(M.ui.time, 'Visible', 'on');
end
%--------------------------------------



%--------------------------------------
function [stimImage RF] = getCurStimImage(M, f, RFvals)
% Get a stimulus image matching the sampling positions as the RF.
% Also returns the RF resampled into a square grid.
x = prfSamplingGrid(M.params);

% account for the different stimuli that are shown next to each other
% f originally refers to the frame in the combined time series across scans:
% we want to break this down into scan n, frame f within that scan.
n = 1; 
nStimScans = numel(M.params.stim);
while n <= nStimScans,
    tmp = f + M.params.stim(n).prescanDuration; 
    if tmp > size(M.params.stim(n).images_org,2),
        f = tmp - size(M.params.stim(n).images_org,2);        
        n = n + 1;
    else
        f = tmp;
        break;
    end
end

% stim image
stimImage     = NaN(size(x));
stimImage(M.params.stim(1).instimwindow) = M.params.stim(n).images_org(:,f);
stimImage     = reshape(stimImage, size(x));

% RF
RF     = NaN(size(x));
RF(M.params.stim(1).instimwindow) = normalize(RFvals, 0, 1);
RF     = reshape(RF, size(x));

return
