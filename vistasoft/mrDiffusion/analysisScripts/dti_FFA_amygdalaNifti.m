function dti_FFA_amygdalaNifti(FIRSTnifti,outFile)

% Usage: dti_FFA_amygdalaNifti([FIRSTnifti],[outFile])
%
% FIRSTnifti='/path/to/subjDir/FIRST/t1_sgm_all_th4_first.nii.gz';
% outFile='/path/to/subjDir/amg_class.nii.gz';
%
% This script uses the FSL FIRST classification to parse out, and
% label, the left and right Amygdalae. This classification can then be
% loaded into itkGray and edited. 
% 
% To use this script you must have already run FIRST using FSL. The file
% that will be read is the output file from FIRST
% (t1_sgm_all_th4_first.nii.gz). 
%
% Default behavior: without any input arguments, the function will allow
% user to browse for the nifti, then save the amygdala nifti in the current
% directory as 'amg_class.nii.gz'.
%
% For information on running FIRST you can visit FSL's website, or the lab
% wiki:
% http://white.stanford.edu/newlm/index.php/Anatomical_Methods#Preprocessin
% g_Using_FSL_Tools_.28ITKGray_Segmentation_Pipeline.29
%
%
% History:
% 06/09/2008 DY modified Bob's mrGrayAnatomy.m for Kids FFA project
% NOTE: for some reason, the uigetfile command isn't working properly. I
% therefore comment it out and require user to have FIRSTnifti input
% correctly. 
% 06/18/2008 See dticreateNiftiFromFIRST for a more general, better version
% of this code. Unfortunately, this is not up yet. 

% if ~exist('FIRSTnifti','file')
%     [FIRSTnifti, path] = uigetfile('*.nii.gz', 'Pick a FIRST segmented nifti file');
%     FIRSTnifti = fullfile(path,FIRSTnifti);
% end

if ~exist('FIRSTnifti','file')
    [FIRSTnifti, path] = uigetfile('*.nii.gz', 'Pick a FIRST segmented nifti file');
    FIRSTnifti = fullfile(path,FIRSTnifti);
end

if ~exist('outFile','var')
    outFile = fullfile(pwd,'amg_class.nii.gz');
end


% Loads the 4D nifti data into variable 'ni'. 
ni=readFileNifti(FIRSTnifti);

% Make sure left and right aren't flipped
ni = niftiApplyCannonicalXform(ni);
firstClass = ni.data(:,:,:,1);
xform = ni.qto_xyz;
clear ni;

% Gets the default labels
labels = mrGrayGetLabels();

c = zeros(size(firstClass),'uint8');
c(firstClass==17) = labels.leftGray; % Left amygdala = 17
c(firstClass==51) = labels.rightGray; % Right amygdala = 51

dtiWriteNiftiWrapper(c, xform, outFile, 1, 'mrGray class file','mrGray',1002);