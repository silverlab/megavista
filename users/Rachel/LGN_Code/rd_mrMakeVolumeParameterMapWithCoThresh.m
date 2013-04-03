% rd_mrMakeVolumeParameterMapWithCoThresh.m
%
% The co field of a parameter map is used for thresholding. This code saves
% your map of choice into the co field of a parameter map.
%                                                                     
% 
% N.B that when viewing parameter maps in the volume, each view is
% auto-scaled separately, so it's a good idea to set the clip mode to
% something fixed.

viewName = 'Volume'; % 'Volume','Gray'
mapPath = 'GLMs/BetaM-P'; % 'GLMs/BetaM-P', 'GLMs/MVP'
threshPath = 'GLMs/Proportion Variance Explained'; % 'Averages.corAnal', 'GLMs/Proportion Variance Explained'
threshField = 'map'; % 'co', 'map'

% files
origMapFile = sprintf('%s/%s.mat', viewName, mapPath);
threshFile = sprintf('%s/%s.mat', viewName, threshPath);
newMapFile = origMapFile;

% load parameter map
viewMap = load(origMapFile);

map = viewMap.map; % eg. volume map
mapName = viewMap.mapName;
mapUnits = viewMap.mapUnits;
cmap = viewMap.cmap;
clipMode = viewMap.clipMode;
numColors = viewMap.numColors;
numGrays = viewMap.numGrays;

% load thresh map (eg. corAnal)
viewThreshMap = load(threshFile);
co = viewThreshMap.(threshField);

save(newMapFile, 'map', 'mapName', 'mapUnits',...
    'cmap', 'clipMode', 'numColors', 'numGrays', 'co')

