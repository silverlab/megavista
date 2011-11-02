%% s_ConvertMapInplaneToVolume
%
% Illustrates how to convert a map in the inplane view to volume space
%
% You might set up a path file that includes vistadata on your path, and
% you might call it vistaDataPath
%
% Stanford VISTA

NEARNBOR    = 'nearest'; % Nearest-neighbor interpolation
TRILINEAR   = 'linear'; % Trilinear interpolation
dataDir     = fullfile(mrvDataRootPath,'functional','vwfaLoc');
pathToMap   = fullfile(dataDir, 'Inplane', 'GLMs', 'FixVWordScrambleWord.mat');

vw_ip   = initHiddenInplane();
vw_ip   = loadParameterMap(vw_ip, pathToMap);
vw_vol  = initHiddenVolume();

scans   = 1; % Default, convert for 1st GLM
saveMap = 1; % Force save of volume map?
method  = TRILINEAR; % Trilinear interpolation

vw_vol  = ip2volParMap(vw_ip, vw_vol, scans, saveMap, method);