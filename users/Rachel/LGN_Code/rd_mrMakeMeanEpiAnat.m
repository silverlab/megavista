% rd_mrMakeMeanEpiAnat.m
%
% mrSave will make Inplane/anat.mat in whatever directory you specify

epi01 = mrLoad('epi01_hemi_mcf.nii.gz','nifti');
epi01_mean = mrComputeMeanMap(epi01);
mrSave(epi01_mean, '.', '1.0anat');