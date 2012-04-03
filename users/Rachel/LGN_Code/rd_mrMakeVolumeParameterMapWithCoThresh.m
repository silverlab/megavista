% rd_mrMakeVolumeParameterMapWithCoThresh.m
%
% The co field of a parameter map is used for thresholding. This code saves
% your map of choice into the co field of a parameter map.
% 
% N.B that when viewing parameter maps in the volume, each view is
% auto-scaled separately, so it's a good idea to set the clip mode to
% something fixed.

origMapFile = 'Volume/GLMs/betas-M-P.mat';
threshFile = 'Volume/Averages/corAnal.mat';
newMapFile = 'Volume/GLMs/BetaM-P.mat';

% load parameter map
volumeMap = load(origMapFile);

map = volumeMap.map;
mapName = volumeMap.mapName;
mapUnits = volumeMap.mapUnits;
cmap = volumeMap.cmap;
clipMode = volumeMap.clipMode;
numColors = volumeMap.numColors;
numGrays = volumeMap.numGrays;

% load thresh map (eg. corAnal)
volumeThreshMap = load(threshFile);
co = volumeThreshMap.co;

save(newMapFile, 'map', 'mapName', 'mapUnits',...
    'cmap', 'clipMode', 'numColors', 'numGrays', 'co')