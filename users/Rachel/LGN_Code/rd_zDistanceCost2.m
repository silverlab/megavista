function [cost thresh] = rd_zDistanceCost2(vals, coords, prop)

[centers voxsInGroup thresh] = rd_findCentersOfMass(coords, vals, prop, 'prop');

% if there are no voxels in one group, set its center to be the center of
% all the voxels -- the centers of the two groups will be the same.
if any(sum(voxsInGroup)==0)
    noVoxGroup = find(sum(voxsInGroup)==0);
    allVoxGroup = find(sum(voxsInGroup)>0);
    centers{noVoxGroup} = centers{allVoxGroup};
end

zDistance = centers{2}(3)-centers{1}(3); % P more dorsal

cost = -1*zDistance; % the larger the distance, the lower the cost