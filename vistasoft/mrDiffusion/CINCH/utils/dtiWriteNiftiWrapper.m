function dtiWriteNiftiWrapper(imArray, matrixTransform, filename, sclSlope, description, intentName, intentCode, freqPhaseSliceDim, sliceCodeStartEndDuration, TR)
%
% dtiWriteNiftiWrapper (imArray, matrixTransform, filename,
%     [sclSlope=1], [description='VISTASOFT'], [intentName=''], [intentCode=0], 
%     [freqPhaseSliceDim=[0 0 0]], [sliceCodeStartEndDuration=[0 0 0 0]])
%
% imArray: the matlab array containing the image
% matrixTransform: a 4x4 matrix transforming from image space to AC-PC
% space.
% filename: Name of the file to output (provide extension).
% sclSlope: 'true' voxel intensity is storedVoxelVale*sclSlope.
% intentName: short (15 char) string describing the intent
% intentCode: an integer specifying a NIFTI intent type. Eg:
%   1002 = NIFTI_INTENT_LABEL (index into a list of labels)
%   1005 = NIFTI_INTENT_SYMMATRIX (e.g., DTI data)
%   1007 = NIFTI_INTENT_VECTOR 
%
% See http://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1.h for
% details on the other nifti options.
%
% HISTORY:
% Author: DA
% 2007.03.27 RFD: we now save the xform in both qto and sto and
% properly set qfac. This improves compatibility with some viewers,
% such as fslview.

if(nargin<2)
  help(mfilename);
end

if ~exist('sclSlope','var') || isempty(sclSlope)
    sclSlope = 1.0;
end
if ~exist('description','var') || isempty(description)
    description = 'VISTASOFT';
end

if ~exist('freqPhaseSliceDim','var') || isempty(freqPhaseSliceDim)
    freqPhaseSliceDim = [0 0 0];
end
if ~exist('sliceCodeStartEndDuration','var') || isempty(sliceCodeStartEndDuration)
    sliceCodeStartEndDuration = [0 0 0 0];
end
if ~exist('intentName','var') || isempty(intentName)
    intentName = '';
end
if ~exist('intentCode','var') || isempty(intentCode)
    intentCode = '';
end
if ~exist('TR','var') || isempty(TR)
    TR = 1;
end

ni = niftiGetStruct(imArray, matrixTransform, sclSlope, description, intentName, intentCode, freqPhaseSliceDim, sliceCodeStartEndDuration, TR);
 
if(length(filename)<4)
    filename = [filename '.nii.gz'];
elseif(strcmpi(filename(end-2:end),'nii'))
    filename = [filename '.gz'];
elseif(length(filename)<6||~strcmpi(filename(end-5:end),'nii.gz'))
    filename = [filename '.nii.gz'];
end
ni.fname = filename;

% Write the file
writeFileNifti(ni);

return;




