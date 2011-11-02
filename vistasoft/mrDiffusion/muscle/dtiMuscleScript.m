% Example of preparing muscle data for dtiFiberUI and MetroTrac

datadir = 'C:\cygwin\home\sherbond\images\tony_nov05\dti2_ser8';
b0Pathname = fullfile(datadir,'dtimaps','B0_001.dcm');
% Use MRIConvert to convert the DICOM anatomy images into NIFTI
t1Pathname = 'C:\cygwin\home\sherbond\images\tony_nov05\ser7\Tony_Sherbondy_12747_7.nii';
outPathname = fullfile(datadir,'analysis','dti2_dt6.mat');
dtiMakeMuscleDt6(b0Pathname, t1Pathname, outPathname);