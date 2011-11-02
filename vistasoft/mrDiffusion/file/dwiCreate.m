function dwi = dwiCreate(dwiNifti, bvecs, bvals)
% Create a dwi structure for use with dwiGet and dwiSet
% 
%   dwi = dwiCreate([dwiNifti=mrvSelectFile],[bvecs=mrvSelectFile],[bvals=mrvSelectFile])
%
% dwiNifti: Path to the nifti image of the motion corrected, ac-pc
%           aligned dwi data
%
% bvecs:    Path to the tab delimeted text file specifying the gradient
%           directions that were applied during the diffusion weighted data
%           acquisition. 
%           Should be a 3xN matrix where N is the number of 
%           volumes
%           NOTE: If you applied motion correction to your 
%           data it is essential that the same rotations were aplied
%           to the vector directions stored in the bvecs file.
%           The convention for mrDiffusion is that a new bvecs file is
%           created and appended with _aligned.
%
% bvals:    Path to the tab delimeted text file specifying the b value
%           applide to each dwi volume.  Should be a 1xN vector where N 
%           is the number of volumes
% 
% Usage Notes:
%           If your bvals and bvecs files have the same name as your
%           dwiNifti (with a .bvec(s) or .bval(s) extension) you only need to
%           point to the dwiNifti and this code will read in the correct
%           files for you. 
% 
% Example:
%           If your bvecs/bvals files are named dwi.bvecs and dwi.bvals:
%            >> dwi = dwiCreate('dwi.nii.gz')
%               dwi = 
%                   nifti: [1x1 struct]
%                   bvecs: [130x3 double]
%                   bvals: [130x1 double]
%           You can also run the functin with no inputs and select your
%           files one by one:
%            >> dwi = dwiCreate;
% 
% Web Resources:
%           mrvBrowseSVN('dwiCreate'):
% 
% See Also:
%           dwiGet.m ; dwiSet.m
% 
% Written by Jason Yeatman 9/22/2011
% (C) Stanford University, VISTA Lab [2011]
%
%% Check inputs
if ~isempty(dwiNifti) && ~exist(dwiNifti,'file')
    error('dwi nifti file does not exist');
elseif ~isempty(bvecs) && ~exist(bvecs,'file');
    error('bvecs does not exist')
elseif ~isempty(bvals) && ~exist(bvals,'file')
    error('bvals file does not exist');
end
%% Create dwi structure
dwi.nifti=[];
dwi.bvecs=[];
dwi.bvals=[];
if exist('dwiNifti','var')
    dwi.nifti = readFileNifti(dwiNifti);
end
if exist('bvecs','var') && ~isempty(bvecs)
    dwi.bvecs = dlmread(bvecs);
end
if exist('bvals','var') && ~isempty(bvals)
    dwi.bvals = dlmread(bvals);
end
% We prefer that the bvals and bvecs are in columns rather than rows
if size(dwi.bvecs,1) == 3
    dwi.bvecs = dwi.bvecs';
elseif size(dwi.bvecs,1) ~= 3 || size(dwi.bvecs,2) ~= 3 || isempty(dwi.bves)
    error('bvecs file must be Nx3 matrix')
end
if size(dwi.bvals,2) == size(dwi.bvecs,1)
    dwi.bvals = dwi.bvals';
elseif size(dwi.bvals,1) ~= size(dwi.bvecs,1) || size(dwi.bvals,2) ~= size(dwi.bvecs,2)
    if ~isempty(dwi.bvecs)
        error('bvals and bvecs files must have the same number of entries')
    end
end
if size(dwi.bvals,1)~=size(dwi.nifti.data,4) || size(dwi.bvecs,1)~=size(dwi.nifti.data,4)
    if ~isempty(dwi.bvecs) && ~isempty(dwi.bvals)
        error('bvals and bvecs must have an entry for every nifti volume')
    end
end
return
