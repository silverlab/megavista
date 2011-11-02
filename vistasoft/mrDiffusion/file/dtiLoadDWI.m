function [dwiData,bvals,bvecs] = dtiLoadDWI(fullPath)
%Load diffusion weighted image and corresponding bvecs/bvals.
%
%  [dwiData,bvals,bvecs] = dtiLoadDWI(fullPath)
%
% INPUTS
%   fullPath: The path where the files dwi.XXX reside
%
% RETURNS
%    dwiData: Nifti structure with the diffusion data.  We always add the
%             bvecs and bvals to the NIFTI structure
%      bvals: Strength of the gradient  (1D) 
%      bvecs: Direction of the gradient (3D)
%
% Web Resources
%    mrvBrowseSVN('dtiLoadDWI');
%
% Example:
%  fullPath=fullfile(mrvDataRootPath,'diffusion','sampleData','raw');
%  [dwiData,bvals,bvecs] = dtiLoadDWI(fullPath);
%
% See also: dtiLoadDt6
%
% Copyright Stanford team, mrVista, 2011

%% Check inputs
if ~exist(fullPath,'dir'), error('No directory %s\n',fullPath); end

dwName = fullfile(fullPath,'dwi.nii.gz');

% Replace with functions that search for 
bvecsName = fullfile(fullPath,'dwi.bvecs');
bvalsName = fullfile(fullPath,'dwi.bvals');

% Vector direction
if ~exist(dwName,'file'), error('No DWI Data');
else  dwiData.nifti = niftiRead(dwName);
end

% dwiData.qto_xyz maps from image space to AC/PC space.
% showMontage(dwiData.data(:,:,:,5))
if ~exist(bvecsName,'file'), error('No bvecs');
else  bvecs   = dlmread(bvecsName)';
end

% size(unique(abs(round(bvecs*100)/100),'rows'))
%
if ~exist(bvalsName,'file'), error('No bvals');
else  bvals = dlmread(bvalsName)';
end

dwiData.bvecs = bvecs;
dwiData.bvals = bvals;


return
