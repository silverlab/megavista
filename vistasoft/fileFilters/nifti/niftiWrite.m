function v = niftiWrite(ni,fName)
%Matlab wrapper for writeFileNifti
%
%  v = niftiWrite(ni,[fName])
%
%
% INPUTS
%
% RETURNS
%
% Web Resources
%
% Example:
%
% Copyright Stanford team, mrVista, 2011

%% Check inputs

if exist('fName','var')
    ni.fname = fName; 
end

writeFileNifti(ni);

return