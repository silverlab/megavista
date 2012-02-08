function dupVoxelPairs = rd_findDuplicateROICoords(coords)

% INPUT:    coords is a matrix of voxel coordinates [3 x number of voxels]
%
% OUTPUT:   dupVoxelPairs gives the duplicate voxel pair indices [number of
%           duplicates x 2]

coords = coords'; % cols are [x y z]

[coordsSorted sortedIdx] = sortrows(coords, [3 2 1]);

nCoords = size(coordsSorted,1);

dupCount = 0;
for iCoord = 1:nCoords-1

    duplicate = all(coordsSorted(iCoord,:)==coordsSorted(iCoord+1,:));
    
    if duplicate
        dupCount = dupCount + 1;
        dupCoords(dupCount,:) = coordsSorted(iCoord,:);
    end
    
end

fprintf('\n%d duplicates found...\n',dupCount)
     
if dupCount==0
    fprintf('finishing\n')
    dupVoxelPairs = [];
else
    fprintf('getting duplicate coordinates...\n')
    % find duplicate voxel indices
    for iDup = 1:dupCount
        if rem(iDup,100)==0
            fprintf('%d\n',iDup)
        else
            fprintf('.')
        end

        dupCoord = dupCoords(iDup,:);

        wDup(:,iDup) = dupCoord(1)==coords(:,1) & dupCoord(2)==coords(:,2) & ...
            dupCoord(3)==coords(:,3);

    end
    fprintf('coordinates found\n')
    [v pair] = find(wDup);

    dupVoxelPairs = reshape(v,2,length(v)/2)';
end

