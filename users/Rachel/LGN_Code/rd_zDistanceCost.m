function cost = rd_zDistanceCost(vals, coords, thresh)

[centers voxsInGroup] = rd_findCentersOfMass(coords, vals, thresh, 'thresh');

% if there are no voxels in one group, set its center to be the center of
% all the voxels -- the centers of the two groups will be the same.
if any(sum(voxsInGroup)==0)
    noVoxGroup = find(sum(voxsInGroup)==0);
    allVoxGroup = find(sum(voxsInGroup)>0);
    centers{noVoxGroup} = centers{allVoxGroup};
end

zDistance = abs(centers{2}(3)-centers{1}(3));

cost = -1*zDistance; % the larger the distance, the lower the cost