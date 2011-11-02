% s_ReadDisplayAnatomy
% Script that reads and displays an antomical data set
%
% Required repositories
%   VISTASOFT
%   VISTADATA
%
% See also: nifti2mrVistaAnat, mrViewer
%
% Last tested version number:  2057
% July 16, 2010

%% Read an anatomy data

% We store mddern anatomies as NIFTI files.  We load the NIFTI anatomy this
% way:
niFileName = fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI','t1.nii.gz');
if ~exist(niFileName,'file')
    error('File not found.  Check vistadata repository');
end

% The anatomy data are int16.  Load them this way.
anat = readFileNifti(niFileName);


%% The data fields in the struct anat

% The variable anat is a structure.
% The image data are in the field anat.data

% Other important files are
anat.xyz_units % Metric units (usually mm)
anat.descrip   % Generic description
anat.fname
anat.dim       % Volume size
anat.pixdim    % Pixel size

% The (x,y,z) dimensions in NIFTI and mrLoadRet coords differ.
% nifti2mrVistaAnat converts NIFTI data into mrLoadRet format.
%
% The NIFTI (x,y,z) format is [sagittal(L:R), coronal(P:A), axial(I:S)]. 
% The mrLoadRet (x,y,z) format is [axial(S:I), coronal(A:P), sagittal(L:R)].
%   L = left, R = right, 
%   P = posterior, A = anterior, 
%   I = inferior,  S = superior
%  

%% To display the anatomy image you can use several methods

% To view a single slice you can extract it directly from the anat.data
% slot
middleSlice = round(anat.dim(3)/2);
img = anat.data(:,:,middleSlice);
imagesc(img)

% You can make a montage of all the slices
montage = imageMontage(anat.data);
imshow(montage)

% It is possible to use itkGray to bring up the file directly.

% From Linux you can use fslview (assuming you have FSL on your path).
% The command is simply 'fslview filename'

% You can call an elaborated Matlab viewer that RAS wrote: mrViewer
mrViewer(niFileName)


%% End

