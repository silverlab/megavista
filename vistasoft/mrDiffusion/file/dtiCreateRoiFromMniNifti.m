function [RoiFileName, invDef, roiMask]=dtiCreateRoiFromMniNifti(dt6File, ROI_img_file, invDef, saveFlag)
%Creates an ROI file in individual space from a NIFTI file with ROI in MNI space. 
%
% [RoiFileName, invDef, roiMask]=dtiCreateRoiFromMniNifti(dt6File, ROI_img_file, [invDef], [saveFlag=false])
%
% Input parameters:
%                   ROI_img_file is an or nii.gz file 
%                   with your ROI in MNI space, provide full path
% Output:           The new ROI is in individual (same as dt6) space. 
%                   The new ROI is saved in folder "ROIs" which is 
%                   located in the same dir as input dt6.  
% 
% The code is mostly borrowwed from RFD findMoriTracts.m. NIFTI image is
% treated as a mask (all the nonzero voxels will make it to the ROI). 
% 
% Time saver: Once computed, MNI<->dt.b0 transformation can be reused to
% apply to any ROI image in MNI space, creating the mrDiffusion ROI file. 
% 
% Example: 
%    dt6File = '/biac3/wandell4/data/reading_longitude/dti_y3/vr060802/dti06/dt6.mat';
%    tdir=fullfile(fileparts(which('mrDiffusion')), 'templates');
%    ROI_img_file1=fullfile(tdir, 'MNI_JHU_tracts_ROIs', 'ATR_roi1_L.nii.gz');
%    ROI_img_file2=fullfile(tdir, 'MNI_JHU_tracts_ROIs', 'ATR_roi2_L.nii.gz');
%    [RoiFileName, invDef, roiMask]=dtiCreateRoiFromMniNifti(dt6File, ROI_img_file1, true)
%    [RoiFileName, invDef, roiMask]=dtiCreateRoiFromMniNifti(dt6File, invDef, ROI_img_file2, true)
%
% See also: 
% dtiImportRoiFromNifti, dtiLoadROIsfromMniNifti
% 
% WEB Resources:
%    mrvBrowseSVN('dtiCreateRoiFromMniNifti')
%
%(c) Vistalab
% 
% HISTORY: 
% ER 04/2008 wrote it 
% ER 07/2009 added output argument invDef and optional input argument invDef 
% ER 09/2009 added an flag to control whether ROI is saved on disk
% 


%% Check the inputs
%
if notDefined('dt6File')
    dt6File = mrvSelectFile('r','*.mat','Select dt6.mat file.');
end

if notDefined('ROI_img_file')
    ROI_img_file = mrvSelectFile('r','*.nii*','Select ROI image file.');
end

if ~exist('saveFlag', 'var') || isempty(saveFlag)
    saveFlag    = false;
    RoiFileName = [];
end

if(~exist('invDef','var') || isempty(invDef))
    computeNorm   = true;
elseif isfield(invDef, 'outMat')
    invDef.outMat = [];
    computeNorm   = false;
end

%% Load dt6.mat
%
dt = dtiLoadDt6(dt6File);


%% Compute spatial normalization
%
if computeNorm
    tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
    template = fullfile(tdir,'MNI_EPI.nii.gz');
    
    [sn, Vtemplate, invDef] = mrAnatComputeSpmSpatialNorm(dt.b0, dt.xformToAcpc, template);
    
    % Check the normalization
    mm        = diag(chol(Vtemplate.mat(1:3,1:3)'*Vtemplate.mat(1:3,1:3)))';
    %bb       = mrAnatXformCoords(Vtemplate.mat,[1 1 1; Vtemplate.dim]);
    bb        = mrAnatXformCoords(Vtemplate.mat,[1 1 1; Vtemplate.dim(1:3)]);
    b0        = mrAnatHistogramClip(double(dt.b0),0.3,0.99);
    b0_sn     = mrAnatResliceSpm(b0, sn, bb, mm, [1 1 1 0 0 0], 0);
    
    tedge     = bwperim(Vtemplate.dat>50&Vtemplate.dat<170);
    im        = uint8(round(b0_sn*255));
    im(tedge) = 255;
    showMontage(im);
end


%% Handle the ROI_img file: Read it, re-slice it and create the mask
%
ROIimg          = readFileNifti(ROI_img_file);
invDef.outMat   = ROIimg.qto_ijk;
bb              = mrAnatXformCoords(dt.xformToAcpc,[1 1 1; size(dt.b0)]);
[ROIdata,xform] = mrAnatResliceSpm(double(ROIimg.data>0), invDef, bb, [1 1 1], [1 1 1 0 0 0]);
% ROIimg         = niftiSetQto(ROIimg,xform,true);% -- use this if you want to save
%                                                     the MNI->ind transformed ROI 
%                                                     image into a 3D mask.
ROIdata(isnan(ROIdata)) = 0;
%ROIimg.data            = ROIdata;
%ROIimg.fname = '\\White\biac3-wandell4\users\elenary\MoriAtlas\MNIT1_JHUT2basedtransform.nii.gz';

% If I take the same img on which est was performed, and then warp it
% with the code below, works perfect. If I take a 2. (Not sure what this
% means) - lmp

% Nonzero voxels
[x1, y1, z1]   = ind2sub(size(ROIdata), find(ROIdata>.3)); %.5 was leaving too many holes
roiMask        = dtiNewRoi(prefix(ROI_img_file, 'short'));
roiMask.coords = mrAnatXformCoords(xform, [x1,y1,z1]);
clear x1 y1 z1;


%% Save the ROI
%
% Save in the dir ROIs associated with your dt6 was
if(strcmp(ROI_img_file((end-1):end), 'gz'))
    ROI_img_file = prefix(ROI_img_file);
end

roiMask = dtiRoiClean(roiMask, [], [0 1 0]);

if saveFlag
    rDir = fullfile(fileparts(dt6File),'ROIs');
    if ~exist(rDir,'dir'); mkdir(rDir); end
    RoiFileName = fullfile(fileparts(dt6File), 'ROIs', [prefix(ROI_img_file, 'short') '.mat']);
    dtiWriteRoi(roiMask, RoiFileName);
end

return