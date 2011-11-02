function pbcCreateBMTestDir(brainDir)
%Create BlueMatter test directory for a Pgbh data set
%
%   pbcCreateBMTestDir(brainDir)
%
% This creates the following directories: phantomDir/bluematter, 
%   phantomDir/bluematter/raw, phantomDir/bluematter/dti**
%
% Inside the raw directory the ideal phantom data from the phantomDir/clean
%   is stored as well as the noisy data as a single NIFTI_GZ file.
%
% AUTHORS:
%   2009.09.05 : AJS wrote it
%
% NOTES: 
%   * I must also manually have the AcPc coordinates be the middle of the
%     image otherwise problems occur when using dtiFiberUI.
%   * Must clear the auto-generated brain mask that dtiRawFitTensorMex
%     produces for dtiFiberUI to work.

if ~isdir(brainDir)
    error('Must provide a valid path to a Pgbh brain directory!');
end

% Directories
rawDir = nfgGetName('rawDir',brainDir);
% Input Files
pbcRawDataFile = nfgGetName('pbcRawDataFile',brainDir);
% Output Files
noisyImg = nfgGetName('noisyImg',brainDir);

% Create new directories
disp(['Creating BlueMatter test directory for ' brainDir ' ...']);
[s,mess,messid] = mkdir(brainDir,'bluematter');
% Only continue if this is a fresh start
if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
    error('Error: Will not overwrite previous bluematter directory!!');
end
mkdir(rawDir);

% Maybe change file type
ni = readFileNifti(pbcRawDataFile);
ni.fname = noisyImg;
m = abs(ni.qto_xyz);
% Must add half voxel offset always for center of image
m(1:3,4) = - ni.pixdim(1:3) .* (ni.dim(1:3)/2+0.5);
ni = niftiSetQto(ni,m);
writeFileNifti(ni);

% Maybe still need to add the voxel offset for center of image

disp(' '); disp('Setting up mrDiffusion files ...');
pbcSetupMRDiffusion(brainDir);

disp(' '); disp('Done.');
return;