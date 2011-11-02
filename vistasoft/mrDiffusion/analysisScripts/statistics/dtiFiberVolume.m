function volume = dtiFiberVolume(fg)
% Calculate the volume (in mm^3) of a fiber group.
%
%   volume = dtiFiberVolume(fg)
%
% The routine accepts either a file name or a cell array of fiber groups.
% It reduces the fiber group list to unique voxels to account for
% redundancy (multiple fibers going through the same voxel). 
%
% This should be used for fibers sampled with 1mm step size and ACPC space
% If the step size is smaller than 1mm, you're still ok.  (RFD)
% 
% Examples:
%   v = dtiFiberVolume;
%
%   fg = dtiReadFibers(fName);
%   v = dtiFiberVolume(fg);
%
%   v = dtiFiberVolume(fName);
%
% By RFD (typed by DY)
% 2007/09/24

% 
if notDefined('fg'), fg = dtiReadFibers; end
if ischar(fg), fg = dtiReadFibers(fg); end

coords = unique(round(horzcat(fg.fibers{:})'),'rows'); 

% Unique handles redundancy (fibers going through same voxel)
% Round makes sure you're on advancing by integer mm units on the grid
volume=size(coords,1);

return;