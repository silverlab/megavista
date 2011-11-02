function volume=dti_FFA_volumeFromNifti(nifti, label)

% Usage: volume = dti_FFA_volumeFromNifti(nifti,label)
%
% nifti = 'full/path/to/file.nii.gz'
% label = 5
%
% This function will take in a nifti that has already been segmented or
% "labeled" using itkgray. This means that for each voxel coordinate in the
% nifti, there are only a few possible values. There are 0's for unlabeled
% voxels, and then for example, a 5 for all voxels labeled as "left gray."
% I'm not sure what the number-->label mapping is in itkgray, but at least
% these relationships seem to be true:
%      left gray = 5
%      right gray = 6
%
% This will find all the voxels with the label that you pass in (e.g., 5)
% and multiply the number of voxels by the voxel dimensions to give you the
% volume in mm^3, assuming that the voxel dimensions are also in mm. 
%
% DY 07/22/2008 with help from JW

am=readFileNifti('amg_class_lucy.nii.gz');
am.pixdim;
inds=find(am.data==label);
[x, y, z] = ind2sub(size(am.data),inds);
% all coordinates, which correspond to itkgray slices containing the label
% these can be plotted: figure; plot3(x,y,z);
coords=[x y z]; 
% make sure there are no duplicates
voxels=unique(coords,'rows');
[numvoxels,tmp]=size(voxels);
volume=numvoxels*prod(am.pixdim);

% There is an easier way to do this, listed below, but I wrote this code in
% case I ever want to go back and check/plot the voxel coords.
% size(find(am.data==label))*prod(am.pixdim); 