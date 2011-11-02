function  ni = dtiRoiNiftiFromMat(matRoi,roiName,saveFlag)
% 
% function dtiRoiNiftiFromMat([matRoi = mrvSelectFile],[roiName],[saveFlag=0])
% 
% This function will read in a matlab roi file (as used in mrDiffusion) and
% convert it to a nifti file that can be loaded in Quench. 
% 
% INPUTS:
%   matRoi   - the .mat roi file you want converted to nifti
%   roiName  - the name for the new nifti roi defaults to
%              [matRoi.name '.nii.gz']
%   saveFlag - 1 = save the ROI, 2 = don't save, just return the struct.
% 
% OUTPUTS:
%   ni       - nifti structure cointaining roi data
%   
%   Saves your roi in the same directory as matRoi with the same
%   name (if you set saveFlag to 1).
% 
% WEB:
%   mrvBrowseSVN('dtiRoiNiftiFromMat');
% 
% EXAMPLE: 
%   matRoi = 'leftLGN.mat';
%   ni     = dtiRoiNiftiFromMat(matRoi);
% 
% 
% (C) Stanford VISTA, 8/2011 [lmp]
% 


%% Read inputs
if ~exist('matRoi','var') || notDefined('matRoi') 
    matRoi = mrvSelectFile('r',{'*.mat';'*.*'},'Select ROI mat file');
    if isempty(matRoi); error('Canceled by user.'); end
end

if ~isstruct(matRoi)
    roi = dtiReadRoi(matRoi);
end

% Set the roiName to be the same as the matRoi if it's not passed in
if ~exist('roiName','var') || notDefined('roiName')
    [p f e] = fileparts(matRoi);
    roiName = fullfile(p,f);
end

if notDefined('saveFlag')
    saveFlag = 0;
end


%% Create the roiImg and xForm from the roi 
[roiImg, imgXform, bb] = dtiRoiToImg(roi);


%% Set ROI as a nifti struct and save
% ni = dtiWriteNiftiWrapper(uint8(roiImg),imgXform,roiName);

ni = niftiGetStruct(uint8(roiImg),imgXform);
ni.fname = roiName;

if saveFlag
    niftiWrite(ni);
    fprintf('Saved: %s.nii.gz \n',roiName);
end


return


