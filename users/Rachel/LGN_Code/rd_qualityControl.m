% rd_qualityControl.m

% FIRST go to _nifni folder

% get current path info
[p f ext] = fileparts(pwd);

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
rd_tsdiffana(epis,[],100) % let the figure handle be 100

% add session name to figure
pos = get(gca,'Position');
text(0.5, pos(2)/2.5, f ,'HorizontalAlignment','center');

%save the output figure
saveas(100,'tsdiffana_output.pdf')

% make mean image
% spm_imcalc_ui('epi01_hemi_mcf.nii', 'myseries_mean.nii', 'mean(X)', {1;0;4;0})
spm_imcalc_ui(epis, 'meanepi.nii', 'mean(X)', {1;0;4;0})

% move QualityControl folder into session directory
cd ..
movefile('QualityControl', p)
