% s_createMesh
% Script (tutorial) to create and visualize a mesh from classification data
%
% Required repositories
%   VISTASOFT
%   VISTADATA
%
% Last tested version number:  2057
% July 16, 2010
%
% (c) mrVista Stanford team

%% Use a modern NIFTI class file

dataD       = mrvDataRootPath;
fName       = fullfile(dataD,'anatomy','anatomyNIFTI','t1_class.nii.gz');
mmPerVox    = [.7 .7 .7]; % voxel dimensions in millimeters 

% Run the build code
msh = meshBuildFromClass(fName, mmPerVox, 'left');
msh = meshSmooth(msh);
msh = meshColor(msh);

% Visualize the mesh
meshVisualize(msh);

%% Use an older mrGray anatomical data set where white was classified

dataD = mrvDataRootPath;
fName = fullfile(dataD,'anatomy','anatomyV','left','left.Class');

% Run the build code
msh = meshBuildFromClass(fName, mmPerVox, 'left');
msh = meshSmooth(msh);
msh = meshColor(msh);

% Visualize the mesh
meshVisualize(msh);


%% The class file contains both left and right.  You can build them both.

dataD = mrvDataRootPath;
fName = fullfile(dataD,'anatomy','anatomyNIFTI','t1_class.nii.gz');

% Run the build code
msh = meshBuildFromClass(fName, mmPerVox, 'right');
msh = meshSmooth(msh);
msh = meshColor(msh);

% Visualize the mesh
meshVisualize(msh);

%% Here is how to save out the mesh
fullName = fullfile(pwd,'deleteMe.mat');
[p n] = fileparts(fullName);
msh = mrmWriteMeshFile(msh, fullName);
disp(['Mesh saved in file ',n,' in directory ',p])
