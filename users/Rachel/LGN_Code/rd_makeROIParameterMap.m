% rd_makeROIParameterMap.m

% This script will make a parameter map that has values of 1 where the ROI
% voxels are and 0 elsewhere. This parameter map can be loaded into the co
% field to threshold maps in a way that masks out everything except the
% ROIs.
%
% Before running, should load all the ROIs you want in this parameter map
% into the Inplane. You should also load a sample Inplane parameter map.

%% setup
mapName = 'ROIX01';
scan = 1;

saveMap = 1;
saveFile = sprintf('Inplane/GLMs/%s.mat', mapName);

%% initialize roi map using the dimensions of a sample, preloaded map
roimap = zeros(size(INPLANE{1}.map{scan}));

nROIs = numel(INPLANE{1}.ROIs);

%% fill the roi map with 1s according to the ROI coordinates
for iROI = 1:nROIs
    coords = INPLANE{1}.ROIs(iROI).coords;
    
    for iCoord = 1:size(coords,2)
        cnow = coords(:,iCoord);
        roimap(cnow(1),cnow(2),cnow(3)) = 1;
    end
end

%% check map
exampleSlice = 8;
figure
imagesc(roimap(:,:,exampleSlice))

%% make map variables
map{scan} = roimap;

%% save map
if saveMap
    save(saveFile, 'map', 'mapName')
end
