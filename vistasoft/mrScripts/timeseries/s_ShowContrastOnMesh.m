%% s_ShowContrastOnMesh
%
% Illustrates how to project a contrast map onto a 3D mesh
%
% You might set up a path file that includes vistadata on your path, and
% you might call it vistaDataPath
%
% Stanford VISTA

%% Initialize the key variables and data path:
dataDir     = fullfile(mrvDataRootPath,'functional','vwfaLoc');
pathToMesh  = fullfile(dataDir, 'deleteMe.mat');
pathToMap   = fullfile(dataDir, 'Gray', 'GLMs', 'FixVWordScrambleWord.mat');
displayMode = 'co'; % Co-thresholded display mode
threshold   = .05; % Co-threshold

%% Load data structure, parameter map, and 3D mesh
vw  = initHiddenGray();
vw  = loadParameterMap(vw, pathToMap);
vw  = meshLoad(vw, pathToMesh, 1);

%% Select display mode and threshold
vw  = viewSet(vw, 'displaymode', 'co');
vw  = viewSet(vw, 'cothresh', threshold);

%% Set bicolor colormap (neg and pos values)
vw  = bicolorCmap(vw);

%% Overlay contrast map onto mesh
vw  = meshColorOverlay(vw); 

%% END