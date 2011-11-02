function ipCoords = ip2functionalCoords(inplane, ipCoords, scan, preserveCoords)
% Convert coordinates from inplane anatomy to inplane functional. We need
% to do this because the resolution of the inplane anatomy is often greater
% than the resolution of the functional data (in the x-y plane, though
% usually not the number slices). Many functions duplicate this code.
% Better to put the function in one place. This is that place. 
%
% ipCoords = ip2functionalCoords(inplane, ipCoords, [scan])
%
%
% JW 7/2010

if ~exist('scan', 'var') || isempty(scan),  scan            = 1;     end
if ~exist('preserveCoords', 'var'),         preserveCoords  = false; end

% num voxels in
nVoxels  = size(ipCoords, 2);

% scale factor
rsFactor = upSampleFactor(inplane, scan)';

% scale 'em
ipCoords = round(ipCoords ./ repmat(rsFactor, [1 nVoxels]));

% remove redunanant voxels
if ~preserveCoords, ipCoords = intersectCols(ipCoords, ipCoords); end

end