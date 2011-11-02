function [vw ok] = loadParameterMap(vw, mapPath)
% function loadParameterMap(vw, [mapPath])
%
% load and set parameter map in a user specified file
%
% mapPath: optional path to parameter map file. Default: prompt user
%
% rmk, 1/12/99
% djh, 2/21/2001, modified to use dataDir and getPathStrDialog
% ras, 02/04, creates an estimated co, amp, and ph fields if they don't
% exist, b/c mrLoadRet is snotty about using parameter maps alone.
%
% ras, 03/11/04: In working with contrast maps, I've found it useful to have 
%  independent statistical threshold and effect size maps -- to restrict
% the map overlay according to the threshold, but to color-code according
% to the effect size. This is analgous to thresholding by coherence, but
% color-coding by amplitude. In this way, for instance, one could leave the
% mapWin at full range, slide the cothresh sliand see both highly correlated
% and anticorrelated regions for a given contrast. 
% So, I've made some param map files that have a 'co' field saved with the
% map and mapName vars. This field, when loaded, would replace the co field
% for the corAnal.
% ARW: It didn't seem right that we estimated co (or had it saved in the
% param file). Instead, we fill co with ones so that it behaves correctly
% ras: Yeah, it's a hack, b/c the variable doesn't generally represent coherence, 
% but for event-related analyses, it's often pretty useful to have the
% two different ways of thresholding. While a long-term solution is to have
% a more generalized display method (which is in the nascent mrVista2
% viewer), it's still nice to have it for now.
%
% ras, 11/15/05: added ability to load map parameters, such as the color
% map and clip modes, which may be saved along with the map.
if ~exist('mapPath','var')
    mapPath = getPathStrDialog(dataDir(vw),'Choose parameter map file name','*.mat');
end

% if the map path doesn't exist, but a map file exists in the view's
% data dir with that name, modify the path accordingly:
if ~check4File(mapPath)
	if check4File( fullfile(dataDir(vw), mapPath) )
		mapPath = fullfile(dataDir(vw), mapPath);
	end
end

if ~check4File(mapPath)
    warning(['No ',mapPath,' file']) %#ok<WNTAG>
	ok = 0;
	return
end

verbose = prefsVerboseCheck;
if verbose
	fprintf('[%s]: Loading Parameter Map: %s \n', mfilename, mapPath);
end

load(mapPath);

vw = setParameterMap(vw,map,mapName);

nScans = viewGet(vw, 'numScans');
if exist('co','var')
	for scan = 1:nScans
		if length(co) >= scan && ~isempty(co{scan}) %#ok<USENS>
			vw.co{scan} = co{scan};
		end
	end
end

% are the units for the map saved?
% (due to inconsistent coding, there are 2 possible variable names.
%  'units' or 'mapUnits'. 'mapUnits' is preferred, but for
%  back-compatibility, I leave in a check for 'units' as well.)
if exist('mapUnits', 'var')
	vw.mapUnits = mapUnits;	
elseif exist('units', 'var')
	vw.mapUnits = units;
else
	vw.mapUnits = ''; % reset to empty
end

% if parameters about the view mode are saved, load these in as well
if exist('cmap','var'), vw.ui.mapMode.cmap = cmap; end
if exist('clipMode','var'), vw.ui.mapMode.clipMode = clipMode; end
if exist('numColors','var'), vw.ui.mapMode.numColors = numColors; end
if exist('numGrays','var'), vw.ui.mapMode.numGrays = numGrays; end

ok = 1;

% refresh (if this isn't a hidden view -- no ui struct)
if isfield(vw, 'ui')
	vw = setDisplayMode(vw,'map');
% 	refreshScreen(view);    
end

return