%% s_convertTalMNI2Volume
%
% Illustrates how to grow discs around coordinates from MNI or Talairach
% space
%
% You might set up a path file that includes vistadata on your path, and
% you might call it vistaDataPath
%
% Stanford VISTA

%% Initialize the key variables and data path:
dataDir     = fullfile(mrvDataRootPath,'functional','vwfaLoc');
pathToMesh  = fullfile(mrvDataRootPath, 'anatomy','anatomyNIFTI', 'leftMesh.mat');

curDir = pwd;
cd(dataDir);

coords      = [-42 -60 -12];
radius      = 10;
roi_name    = 'Middle Temporal';

%%
% WARNING
% Make sure you init your volume and gray views first!
% See: s_initGrayAndVolume.m

%% Load grown disk into view data structure
vw = findTalairachVolume([], 'path', pwd, 'Talairach', coords, 'name', roi_name, 'radius', radius); % 'MNI' can be replaced with 'Talairach' or 'Tal'
% To add further ROIs, pass in vw as the first argument and it will be
% appended to its ROI list

%% Open 3D mesh
vw = meshLoad(vw, pathToMesh, 1); % If pathToMesh is [], will open dialog box

%% Overlay ROI onto mesh
vw = viewSet(vw, 'recomputev2gmap'); 
vw = viewSet(vw, 'roidrawmethod', 'filled perimeter'); % other options: 'boxes', 'filled perimeter', 'patches'
vw = meshColorOverlay(vw); 

cd(curDir);
%% END