% t_meshCreate
%
% Tutorial on how to create and visualize a mesh from classification data.
%
% Stanford VISTA
%

%% Use a modern NIFTI class file (suggested)
dataDir     = mrvDataRootPath;
classDir	= fullfile(dataDir, 'anatomy', 'anatomyNIFTI');
fName       = fullfile(classDir, 't1_class.nii.gz');
niftiImage  = readFileNifti(fName, []);  % Read just the header
mmPerVox    = niftiImage.pixdim;         % Get the pixel size

% Run the build code, perform smoothing/coloring
msh = meshBuildFromClass(fName, mmPerVox, 'left'); % 'right' also works
msh = meshSmooth(msh);
msh = meshColor(msh);

% mshFile = fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI','leftMesh.mat');
% load(mshFile)
%
% Visualize the mesh
meshVisualize(msh);

%% Use an older mrGray anatomical data set where white was classified
dataDir = mrvDataRootPath;
classDir = fullfile(dataDir, 'anatomy', 'anatomyV', 'left');
fName = fullfile(classDir,'left.Class');

% Run the build code, perform smoothing/coloring
msh = meshBuildFromClass(fName, mmPerVox, 'left');
msh = meshSmooth(msh);
msh = meshColor(msh);

% Visualize the mesh
meshVisualize(msh);

%% Here is how to save out the mesh
fullName = fullfile(classDir, 'leftMesh.mat');
[p n] = fileparts(fullName);
msh = mrmWriteMeshFile(msh, fullName);
disp(['Mesh saved in file ',n,' in directory ',p])
