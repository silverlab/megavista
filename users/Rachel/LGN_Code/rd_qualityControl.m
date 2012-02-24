% rd_qualityControl.m

% FIRST go to _nifni folder

% get current path info
[p f ext] = fileparts(pwd);

okgo = input(sprintf('\nCurrent directory is %s. Ok to continue? (y/n) ', f), 's');

if ~strcmp(okgo,'y')
    error('no go - stopping!')
end

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

% add session name to figure
h1 = axes('Position', [0 0 1 1], 'Visible', 'off');
text(0.5, 0.01, sprintf('%s  First image: %s', f, epis{1}), 'HorizontalAlignment','center');

%save the output figure
saveas(gcf,'tsdiffana_output.pdf')

% make mean image
% spm_imcalc_ui('epi01_hemi_mcf.nii', 'myseries_mean.nii', 'mean(X)', {1;0;4;0})
spm_imcalc_ui(epis, ['mean' epis{1}], 'mean(X)', {1;0;4;0})

% make var image
% spm_imcalc_ui(epis, ['var' epis{1}], 'var(X)', {1;0;4;0}) % identical to
% tsdiffana's vmean

% delete the epi niftis from the QualityControl directory
!rm epi*.nii

% move QualityControl folder into session directory
cd ..
movefile('QualityControl', p)
