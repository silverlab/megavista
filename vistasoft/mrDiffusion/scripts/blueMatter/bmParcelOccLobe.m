%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Script for parcellating the occipital lobe and asking how the occipital
% lobe communicates with the rest of the brain
%
% Tracing assumptions:
% - Assume that the subject already has gm*.nii.gz and wm*.nii.gz, where * is
% RH and LH.  For Occipital lobe tracing this means that the gmRH file
% would be greater than zero for all voxels that are in right hemisphere
% gray matter as well as the occipital-parietal plane that separates
% occipital lobe from the rest of the brain.
%
% Scoring assumptions:
% - Assume that we already have an ecc.nii.gz file that gives eccentricity 
% values for gray matter locations.
% - Assume that there is a white matter template matched to this image in
% filename??
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% What subject and other directory type stuff to send to the bm functions
subjectDir = '/khaki/scr1/bluematter/rb090930';
binDir = bmGetName('binDir',subjectDir);
fiberDir = bmGetName('fiberDir',subjectDir);
tissue_maskFile = bmGetName('tissue_maskFile',subjectDir);

% First, lets create GM and WM masks from the tissue mask
tm = readFileNifti(tissue_maskFile);
% Create simple convolution kernel to only leave boundaries
M = zeros([3,3,3]);
M(:,:,2) = [0 1 0; 1 1 1; 0 1 0];
M(2,2,1) = 1;
M(2,2,3) = 1;
wm = zeros(size(tm.data));
wm(tm.data>0) = 1;
gm = convn(wm,M,'same');
%gm = wmc;
gm(gm>6)=0;
gm(gm>0) = 1;



sttLHPDB = fullfile(fiberDir,'sttLH.pdb');
sttRHPDB = fullfile(fiberDir,'sttRH.pdb');

% Create left hemisphere pathways
copyfile(fullfile(binDir,'gmLH.nii.gz'),fullfile(binDir,'gm.nii.gz'));
copyfile(fullfile(binDir,'wmLH.nii.gz'),fullfile(binDir,'wm.nii.gz'));
[fgSTT, fgTrackVis] = bmCreatePDBs(subjectDir);
% XXX Combine the tracks to create one composite set.
% Add the desired statistics
% Add the eccentricity of endpoint value
ecc = readFileNifti(fullfile(binDir,'ecc.nii.gz'));
fgSTT = dtiClearQuenchStats(fgSTT);
fgSTT = dtiCreateQuenchStats(fgSTT,'ECC_max','ECC', 1, ecc, 'max'); 
% Save out to the correct file
mtrExportFibers(fgSTT, sttLHPDB);
disp('Finished processing left hemisphere occipital lobe.');

% XXX Create right hemisphere pathways
copyfile(fullfile(binDir,'gmRH.nii.gz'),fullfile(binDir,'gm.nii.gz'));
copyfile(fullfile(binDir,'wmRH.nii.gz'),fullfile(binDir,'wm.nii.gz'));
[fgSTT, fgTrackVis] = bmCreatePDBs(subjectDir);
% XXX Combine the tracks to create one composite set.
% Add the desired statistics
% Add the eccentricity of endpoint value
ecc = readFileNifti(fullfile(binDir,'ecc.nii.gz'));
fgSTT = dtiClearQuenchStats(fgSTT);
fgSTT = dtiCreateQuenchStats(fgSTT,'ECC_max','ECC', 1, ecc, 'max'); 
% Save out to the correct file
mtrExportFibers(fgSTT, sttRHPDB);
disp('Finished processing right hemisphere occipital lobe.');

