function createNoDataPDF(subDir)

% Usage: createNoDataPDF(subDir)
% Example: createDegradedPDF('full/path/to/subDir')
%
% This function creates and saves a pdfNoData.nii.gz in subDir/dti30/bin
% that is homogenized in shape (directionality) such that the tensors no
% longer contain any information from the original dataset (hence
% "NoData"). It is a more specific, and easy to implement case of the
% createDegradedPDF function that I hope to implement soon. Hence, we
% create PARAMS and OPTS struct variables that in a future version can be
% passed in as input arguments to allow parametric tensor degradation. For
% now, we just set these variables to a fixed value, the value that would
% result in a "NoData" pdf nifti. 
%
% Since conTrack only knows about and uses the pdf.nii.gz file during
% tracking and scoring, we only have to modify this file, not
% tensors.nii.gz or anything else, etc.
%
% PDF.NII.GZ structure:
% XxYxZx14, where each voxel has 14 values
% v1-3: EigVec3 (x,y,z) or Radial
% v4-6: EigVec2 (x,y,z) or Radial
% v7-9: EigVec1 (x,y,z) or Longitudinal Vector
% v10: -Concentration about EigVec1 from DTI data
% v11: -Concentration about EigVec1 from DTI data (10/11 are repeats)
% v12: Linearity
% v13: EigenValue2
% v14: EigenValue3
%
% KEY VARIABLES (potential input structs):
% * params.tensorShapeSphericity: value from 0 to 1 where 1 moves the tensor shape to that of a
% perfect sphere, and 0 does not modify the starting tensor shape
% * params.volumeOfTensor: value from 0 to 1 where 1 moves the original volume of each
% tensor to value, and 0 does not modify the starting volume
% * params.dataDispersionUncertainty: value from 0 to 1 where 1 moves the
% data dispersion estimate (measure of uncertainty in the data, potential
% min is 0) to maximum (dispersion on a sphere, 54.4 degrees).
% * opts.volumeOfTensorMatching: 'mean'= use mean volume of all tensors, no other options are
% implemented yet
% * opts.pdf: 1 = pdf.nii.gz already computed (using ctrPDFFile.m), start
% here when constructing pdfNoData.nii.gz; 0 = create pdf.nii.gz file first
% (e.g., if one does not already exist). 
% * see dtiDegradeTensorShape function for more information. 
% 
% History
% 2009/02/07: DY wrote it


% Set PARAMS and OPTS this way for "No Data" spherical tensor shape case.
% Check implementation before setting params/opts for volume (commented
% out). Also, params.dataDispersionUncertainty is not fully implemented,
% currently on case in which it works is if it's set to the maximum. 
% [params.tensorShapeSphericity, params.dataDispersionUncertainty] =deal(0); % no change, for debugging
[params.tensorShapeSphericity, params.dataDispersionUncertainty]=deal(1); % "no data"
% opts.volumeMatchingMethod='mean'; params.volumeOfTensor=1; 
opts.shapeSpherizingMethod='westinShapes_l1'; opts.pdf=1;

% The function takes the data from an XxYxZx6 matrix to an Nx6 matrix for use
% with the dtiDegradeTensorShape function. 
dt=dtiLoadDt6(fullfile(subDir,'dti30','dt6.mat'));

% Degrade the tensors
fprintf('\n We are about to use dtiDegradeTensorShape.m\n');
[dtDegraded, tmp] = dtiDegradeTensorShape(dt.dt6, params.tensorShapeSphericity,...
    opts.shapeSpherizingMethod);

fprintf('\n We have just finished using dtiDegradeTensorShape.m\n');

% Turn dispersion to maximum (54.4 degrees)
[X Y Z numDirs]=size(dt.dt6);
dtDispersion=repmat(deg2rad(54.4),[X Y Z]);

% TOP LEVEL COMMENT: alter dtiDegradeTensorShape so that it takes in and
% outputs XxYxZx6 matrices (instead of Nx6, which are annoying to handle). 

% If the subject doesn't already have a standard PDF, create one
p.dt6Dir=fullfile(subDir,'dti30');
if ~exist(fullfile(p.dt6Dir,'bin','pdf.nii.gz'))
    ctrPDFFile(p);
end

% Then write the "no data" PDF
params.dt6=dtDegraded;
params.pdfName='pdfNoData.nii.gz';
params.eig1Concentration= - 1 ./ sin(dtDispersion).^2;  % convert dispersion to "concentration"
fprintf('\n We are on line 84 of createNoDataPDF.m\n');
ctrPDFFile(p,params);

return;


% To check tensors
nonzeros=find(dtDegraded);
[x y z sixes]=ind2sub(size(dtDegraded),nonzeros);

% dt.dt6 and dtDegraded should be identical if params = 0, original
dt.dt6(x(200),y(200),z(200),:)
dtDegraded(x(200),y(200),z(200),:)

% all eigVals should be equal to each other if params = 1 sphericize
[eigVec, eigVal] = dtiEig(dtDegraded(x(200),y(200),z(200),:));
