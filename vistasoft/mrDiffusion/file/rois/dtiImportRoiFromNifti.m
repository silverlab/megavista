function roi = dtiImportRoiFromNifti(roi_img, outFile)
% roi = dtiImportRoiFromNifti(roi_img, outFile)
% 
% Creates a mrDiffusion ROI structure from a binary NIFTI image. 
% 
% Note: all filenames should have prefixes only
% 
% WEB RESOURCES:
%   mrvBrowseSVN('dtiImportRoiFromNifti');
% 
% HISTORY:
% 2008.04.21 ER wrote it.
% 

% Can either be a NIFTI filename or a NIFTI struct
RoiIm = readFileNifti(roi_img);

% Pull ou the coordinates from RoiIm.data
[x1,y1,z1] = ind2sub(size(RoiIm.data), find(RoiIm.data));

% Initialize roi structrue
roi = dtiNewRoi(prefix(roi_img, 'short'));

% Xform the coordianates based on the Xform in the nifti image
roi.coords = mrAnatXformCoords(RoiIm.qto_xyz, [x1,y1,z1]);

% Save the nifti if the user passed in outFile
if exist('outFile','var') && ~isempty(outFile)
    dtiWriteRoi(roi, outFile);
    fprintf('Saved %s \n',outFile);
else
end

return;
