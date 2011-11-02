function ni = niftiCreate
%Initialize a nifti data structure used in Vistasoft
%
%   ni = niftiCreate
%
% We need a document to describe which fields we support and the meaning of
% those fields.  Maybe Rainer will write it.
%
% INPUTS
%
% RETURNS
%
% Web Resources
%   mrvBrowseSVN('niftiCreate.m')
%   http://www.mathworks.com/matlabcentral/fileexchange/8797
%
% Example:
%
% Copyright Stanford team, mrVista, 2011

%% These fields are the ones used in the m-file readFileNifti

%  The default behavior of niftiRead is to return an empty nifti structure.
%  The file niftiGetStruct currently initializes a nifti structure with
%  arguments that are passed in.
ni = niftiRead;


return;