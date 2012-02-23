% rd_qualityControl.m

% FIRST go to _nifni folder

% organize files, unzip niftis
!mkdir QualityControl
!cp epi*hemi.nii.gz QualityControl
!cp epi*mp.nii.gz QualityControl
cd QualityControl
!gunzip *.nii.gz

% get epi file names
epiFiles = dir('epi*');
for iFile = 1:length(epiFiles)
    epis{iFile} = epiFiles(iFile).name;
end

% tsdiffana
% tsdiffana('epi01_hemi_mcf.nii')
rd_tsdiffana(epis)

% make mean image
spm_imcalc_ui('epi01_hemi_mcf.nii', 'myseries_mean.nii', 'mean(X)', {1;0;4;0})