% rd_mrMakeMeanEpiAnat.m
%
% mrSave will make Inplane/anat.mat in whatever directory you specify
%
% use fslmaths to make mean nifti files: fslmaths inputvol -Tmean outputvol

epi01 = mrLoad('epi01_fix_mcf.nii.gz','nifti');
epi01_mean = mrComputeMeanMap(epi01);
mrSave(epi01_mean, '.', '1.0anat');
