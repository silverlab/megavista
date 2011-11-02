%% s_ConvertMapInplaneToGray
%
% Illustrates how to convert a map in the inplane view to gray space
%
% You might set up a path file that includes vistadata on your path, and
% you might call it vistaDataPath
%
% Stanford VISTA

NEARNBOR    = 'nearest'; % Nearest-neighbor interpolation
TRILINEAR   = 'linear'; % Trilinear interpolation

dataType    = 'GLMs';
dataDir     = fullfile(mrvDataRootPath,'functional','vwfaLoc');
pathToMap   = fullfile(dataDir, 'Inplane', 'GLMs', 'FixVWordScrambleWord.mat');

vw_ip       = initHiddenInplane();
vw_ip       = viewSet(vw_ip, 'currentDataType', dataType);
vw_gray     = initHiddenGray();
vw_gray     = viewSet(vw_gray, 'currentDataType', dataType);

vw_ip   = loadParameterMap(vw_ip, pathToMap);

scans   = 0; % Flag to convert for all scans
saveMap = 1; % Force save of volume map?
method  = TRILINEAR; % Trilinear interpolation

vw_gray  = ip2volParMap(vw_ip, vw_gray, scans, saveMap, method);