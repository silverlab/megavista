function [centers voxsInGroup thresh] = rd_findCentersOfMass(coords, vals, x, xType)
%
% function [centers voxsInGroup thresh] = rd_findCentersOfMass(coords, vals, x, xType)
%
% Inputs: 
% coords is a n x 3 vector of coordinates for each voxel
% vals are the associated values for the voxels with these coords
% x is either thresh or prop. 
% - thresh is the threshold value used for defining two groups of voxels. we
%   want to find the center coordinate of these two groups.
% - prop is the proportion of voxels that will be in group 1 (above the
%   threshold).
% xType is a string, either 'thresh' or 'prop' to give the type of x
%
% Outputs:
% centers is a 2-element cell array containing the xyz central coordinates
% of each of the two groups
% voxsInGroup is an n x 2 logical array indicating whether a given n voxel
% is in each of the two groups
% thresh is the threshold value used for defining the two groups of voxels.
% it may be given as input, or found, if x is prop.

% coords = data(1).lgnROICoords';
% nVox = size(coords,1);
% vals = rand(nVox,1);
% thresh = .5;

switch xType
    case 'thresh'
        thresh = x;
        prop = [];
    case 'prop'
        prop = x;
        thresh = [];
    otherwise
        error('xType not recognized. should be thresh or prop')
end

% if given prop, find thresh
if isempty(thresh)
    valsSorted = sort(vals);
    thresh = valsSorted(round(numel(vals)*(1-prop)));
end

% check that coords and vals are the same length
if size(vals,1)~=size(coords,1)
    error('coords and vals have different lengths!')
end

voxsInGroup(:,1) = vals>thresh;
voxsInGroup(:,2) = vals<=thresh;

for iGroup = 1:size(voxsInGroup,2)
    coordsInGroup{iGroup} = coords(voxsInGroup(:,iGroup),:);
    centers{iGroup} = mean(coordsInGroup{iGroup},1);
end

