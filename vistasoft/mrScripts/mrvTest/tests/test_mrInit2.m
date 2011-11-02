function test_mrInit2
% function test_mrInit2
% 
%  This is a test function to validate the mrInit2 is doing the right thing
%
% INPUTS
%
% No inputs
%
% RETURNS
%  No returns
% Web Resources
%
%
% Copyright Stanford team, mrVista, 2011



%% Set up the data: 

nifti_path = fullfile(mrvDataRootPath,'validate','fmri');    

% These files all contain a part of a real data set preprocessed using 
% Kendrick's preprocessing script: 
epi_file = fullfile(nifti_path, 'epi01.nii.gz');
inplane_file = fullfile(nifti_path, 'inplane.nii.gz'); 
anat_file = fullfile(nifti_path, 't1.nii.gz'); 

% Make the sessiondir in the system-defined tempdir:  
sess_path = fullfile(tempdir,'mrSession');

% Generate the expected generic params structure
params = mrInitDefaultParams;

% And insert the specific inputs: 
params.inplane = inplane_file; 
params.functionals = {epi_file}; 
params.vAnatomy = anat_file;
params.sessionDir = sess_path; 

% Run it: 
ok = mrInit2(params); 

%% Test the results of this: 

% First, just make sure it runs through: 
assertEqual(ok, 1)


% Do the outputs make sense? Compare to a read from the data files: 
epi_nii = readFileNifti(epi_file); 
inplane_nii = readFileNifti(inplane_file); 

mrs = load(fullfile(sess_path,'mrSESSION.mat'));
func = mrs.mrSESSION.functionals; 
ip = mrs.mrSESSION.inplanes; 
dt = mrs.dataTYPES; 

%% From the EPI data:  
% Did you get the right voxel size? 
assertEqual(func.voxelSize, epi_nii.pixdim(1:end-1));

% And TR? 
assertEqual(func.framePeriod, epi_nii.pixdim(end));
% Which is also saved in dataTypes: 
assertEqual(dt.scanParams.framePeriod, epi_nii.pixdim(end));

% Inplane dimensions: 
assertEqual(func.fullSize, epi_nii.dim(1:2)); 
% also in dt (there's no crop per default): 
assertEqual(dt.scanParams.cropSize, epi_nii.dim(1:2)); 

% Number of slices: 
assertEqual(length(func.slices), epi_nii.dim(3)); 

% Number of TRs: 
assertEqual(func.nFrames, epi_nii.dim(end)); 
% also  in dataTYPES:
assertEqual(dt.scanParams.nFrames, epi_nii.dim(end)); 

% Let's go and verify the time-series themselves. Load the data from some
% random slice: 
slice_idx = ceil(rand * length(func.slices)); 

mat_series = load(sprintf(fullfile(sess_path,...
               'Inplane/Original/TSeries/Scan1/tSeries%i.mat'),slice_idx));

assertEqual(reshape(mat_series.tSeries,136,func.fullSize(1),func.fullSize(2)),...
    permute(single(squeeze(epi_nii.data(:,:,slice_idx,:))),[3,1,2]));

%% From the inplane anatomical data: 

% Voxel dimensions: 
assertEqual(ip.voxelSize, inplane_nii.pixdim); 

% Number of slices: 
assertEqual(ip.nSlices, inplane_nii.dim(end)); 

% Inplane dimensions: 
assertEqual(ip.fullSize, inplane_nii.dim(1:2)); 

% Verify the inplane anatomy that got generated: 
mat_anat = load(fullfile(sess_path,'Inplane/anat.mat')); 
% Up to a conversion in data type: 
assertEqual(single(inplane_nii.data),mat_anat.anat)

