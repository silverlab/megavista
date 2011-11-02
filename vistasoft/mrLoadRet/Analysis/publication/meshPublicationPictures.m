% This script loads functional data from a mrVista directory and displays
% it on a mesh. Several images of the mesh are saved.  It is useful for
% creating a series of images for Supplementary Figures, showing the entire
% data set.
%
% The script works without opening a mrVista window.
%
% Kaoru created the script for the supplementary figures in his TO maps.
% The specific dataType (Average) and experimental parameter files will
% differ for each application.  This script is a good template for seeing
% how to automate the process of creating these publication images.
%
% Notes:
%
%   1.  Before running this script, make sure the mrMesh server is started ('mrmStart'). 
%   2.  Notice that writing the file requires permuting the RGB data. Weird
%       and this should be encapsulated in a function when I understand it.
%
% Example :
%
%   We run a sequence of calls like these in a loop from another script.
%   That way we cycle through all of the subjects' data.
%   An example of a single loop for a single subject is:
%
%     dataFolder = '/biac3/wandell5/data/MT/YM070815/'
%     pRFfile = 'retModel-20080605-193415-sFit-sFit.mat'
%     rot_l = -pi*40/180;
%     rot_r = pi*(1-40/180);
%     meshPublicationPictures    
% 
% 08/08 KA wrote it
%

%% mesh view settings
host = 'localhost';
pitch_l = pi*170/180;
pitch_r = pi*170/180 - pi;
zoom    = 2.4;
wWidth  = 1200; % Mesh window width
wHeight = 800;  % Mesh window height
f.filename = 'nosave';

%% load VOLUME structure
cd(dataFolder);
mkdir paper_figures
VOLUME{1} = initHiddenGray;
% mrVista 3

% open left mesh and set the camera angle
mshFileName = strcat(fileparts(getVAnatomyPath),'/Left/3DMeshes/left_mesh_128.mat');
displayFlag = 1;
VOLUME{1} = meshLoad(VOLUME{1}, mshFileName, displayFlag);
msh = viewGet(VOLUME{1},'curMesh');
mrmSet(msh,'windowSize',wHeight,wWidth);
id_l = VOLUME{1}.mesh{1}.id;
mrmRotateCamera(id_l, [pitch_l pi/4 rot_l], zoom);

% open right mesh and set the camera angle
mshFileName = strcat(fileparts(getVAnatomyPath),'/Right/3DMeshes/right_mesh_128.mat');
displayFlag = 1;
VOLUME{1} = meshLoad(VOLUME{1}, mshFileName, displayFlag);
msh = viewGet(VOLUME{1},'curMesh');
mrmSet(msh,'windowSize',wHeight,wWidth);
id_r = VOLUME{1}.mesh{2}.id;
mrmRotateCamera(id_r, [pitch_r pi/4 rot_r], zoom);

% save pictures of anatomy, no overlay or ROIs
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_anatomy.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_anatomy.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% load ROIs
VOLUME{1} = setDisplayMode(VOLUME{1},'anat'); 
[VOLUME{1}, ok] = loadROI(VOLUME{1}, ...
    {'l-LO1-atlas';'l-LO2-atlas';'l-TO1-atlas';'l-TO2-atlas'; ...
    'r-LO1-atlas';'r-LO2-atlas';'r-TO1-atlas';'r-TO2-atlas'},[],[],0,1);
VOLUME{1}.ui.showROIs = -2;
VOLUME{1}.ui.roiDrawMethod = 'patches';
VOLUME{1} = refreshScreen(VOLUME{1});
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
VOLUME{1} = meshColorOverlay(VOLUME{1});

% save pictures of anatomy with ROIs
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_anatomy_ROIs.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_anatomy_ROIs.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% hide ROIs for the plot of functional data
VOLUME{1}.ui.showROIs=0;
% plot ROIs outline
% for ii=1:8
%     VOLUME{1}.ROIs(ii).color = 'k';
% end
% VOLUME{1}.ui.roiDrawMethod = 'perimeter'

% open 'Averages' dataType and load pRF data
for ii=1:size(dataTYPES,2)
    if strcmp(dataTYPES(ii).name,'Averages')==1
        VOLUME{1}.curDataType = ii; %#ok<AGROW>
        disp('Averages found');
        break;
    end
end
VOLUME{1} = rmSelect(VOLUME{1}, 2, strcat(pwd,'/Gray/Averages/',pRFfile));
VOLUME{1} = rmLoadAsWedgeRing(VOLUME{1});

% save pictures of angle map
VOLUME{1} = setDisplayMode(VOLUME{1},'ph'); 
VOLUME{1} = cmapImportModeInformation(VOLUME{1}, 'phMode', 'WedgeMapLeft_pRF.mat');
VOLUME{1} = refreshScreen(VOLUME{1});
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_angle.png';
VOLUME{1} = cmapImportModeInformation(VOLUME{1}, 'phMode', 'WedgeMapRight_pRF.mat');
VOLUME{1} = refreshScreen(VOLUME{1});
imwrite(permute(res.rgb,[2,1,3])./255, fname);
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_angle.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% save pictures of eccentricity map
VOLUME{1} = setDisplayMode(VOLUME{1},'map'); 
VOLUME{1} = refreshScreen(VOLUME{1});
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_ecc.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_ecc.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% save pictures of pRF size map
VOLUME{1} = setDisplayMode(VOLUME{1},'amp'); 
VOLUME{1} = refreshScreen(VOLUME{1});
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_size.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_size.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% open 'MT+_localizer' dataTYPE and load MT/MST localizer data
for ii=1:size(dataTYPES,2)
    if strcmp(dataTYPES(ii).name,'MT+_localizer')==1
        VOLUME{1}.curDataType = ii;
        disp('MT+_localizer found');
        break;
    end
end
VOLUME{1} = loadCorAnal(VOLUME{1}); 
VOLUME{1} = setCothresh(VOLUME{1}, .4);

% save pictures of left motion localizer
VOLUME{1}.curScan = 1;
VOLUME{1} = setDisplayMode(VOLUME{1},'co'); 
VOLUME{1}.ui.coMode=setColormap(VOLUME{1}.ui.coMode, 'hotCmap');
VOLUME{1} = refreshScreen(VOLUME{1});
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_LMotion_04.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_LMotion_04.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% save pictures of right motion localizer
VOLUME{1}.curScan = 2;
VOLUME{1} = refreshScreen(VOLUME{1});
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_RMotion_04.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_RMotion_04.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% save pictures of center motion localizer
VOLUME{1}.curScan = 3;
VOLUME{1} = refreshScreen(VOLUME{1});
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_CMotion_04.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_CMotion_04.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% save pictures of LOC localizer
VOLUME{1}.curScan = 4;
VOLUME{1} = refreshScreen(VOLUME{1});
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_l, 'screenshot', f);
fname = './paper_figures/left_LOC_04.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
VOLUME{1} = meshColorOverlay(VOLUME{1}); 
[id,stat,res] = mrMesh(host, id_r, 'screenshot', f);
fname = './paper_figures/right_LOC_04.png';
imwrite(permute(res.rgb,[2,1,3])./255, fname);

% End script
