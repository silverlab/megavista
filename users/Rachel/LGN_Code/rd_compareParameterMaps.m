% rd_compareParameterMaps.m

% Compare parameter maps within a single ROI, for example two parameter
% maps from separate scanning sessions.
% Currently assumes parameter maps from the different sessions have the 
% same name.
% Default is to look in the session 1 directory for the ROI and the view
% coordinates.

%% setup
view = 'Volume';
dataType = 'GLMs';
mapName = 'BetaM-P';
roiName = 'ROI201-i3T7T';

% set map idxs in case there are multiple scans in this data type
map1Idx = 1;
map2Idx = 2;

%% file i/o
studyDir = '/Volumes/Plata1/LGN/Scans';
session1Dir = '3T/RD_20120205_session/RD_20120205_n';
session2Dir = '7T/RD_20111214_session/RD_20111214';

viewCoordsExtension = sprintf('%s/coords.mat', view);
mapExtension = sprintf('%s/%s/%s.mat', view, dataType, mapName);
roiExtension = sprintf('%s/ROIs/%s.mat', view, roiName);

view1CoordsPath = sprintf('%s/%s/%s', studyDir, session1Dir, viewCoordsExtension);
view2CoordsPath = sprintf('%s/%s/%s', studyDir, session2Dir, viewCoordsExtension);
map1Path = sprintf('%s/%s/%s', studyDir, session1Dir, mapExtension);
map2Path = sprintf('%s/%s/%s', studyDir, session2Dir, mapExtension);
roiPath = sprintf('%s/%s/%s', studyDir, session1Dir, roiExtension);

%% load coords, maps, roi
view1Coords = load(view1CoordsPath);
view1Coords = view1Coords.coords;
view2Coords = load(view2CoordsPath);
view2Coords = view2Coords.coords;
map1 = load(map1Path);
map2 = load(map2Path);
roi = load(roiPath);

%% get map data and ROI coords
map1Data = map1.map{map1Idx};
map2Data = map2.map{map2Idx};

roiCoords = roi.ROI.coords;

%% logical maps - 1 if in ROI, 0 if not
inROIMap1 = zeros(size(map1Data));
for iCoord = 1:size(roiCoords,2)
    coords = roiCoords(:,iCoord);
    inROIMap1 = inROIMap1 + ...
        (view1Coords(1,:) == coords(1) & ...
        view1Coords(2,:) == coords(2) & ...
        view1Coords(3,:) == coords(3));
end
inROIMap1 = logical(inROIMap1);

inROIMap2 = zeros(size(map2Data));
for iCoord = 1:size(roiCoords,2)
    coords = roiCoords(:,iCoord);
    inROIMap2 = inROIMap2 + ...
        (view2Coords(1,:) == coords(1) & ...
        view2Coords(2,:) == coords(2) & ...
        view2Coords(3,:) == coords(3));
end
inROIMap2 = logical(inROIMap2);

% see also, from getCurDataROI:
% [commonCoords indRoi indView] = intersectCols(roi.coords, vw.coords);
% (not sure if this does the same thing)

%% get map vals from ROI
map1ROIVals = map1Data(inROIMap1)';
map2ROIVals = map2Data(inROIMap2)';

map1ROIZ = (map1ROIVals - mean(map1ROIVals))./std(map1ROIVals);
map2ROIZ = (map2ROIVals - mean(map2ROIVals))./std(map2ROIVals);

mapValCorr = corr(map1ROIVals, map2ROIVals);

%% labeling by m/p class
% Note: this is class as determined from Volume voxels in this new common
% ROI -- not the original Inplane-based classification in session-specific
% ROIs.
[c1 vig1 th1] = rd_findCentersOfMass(roiCoords', map1ROIVals, .2, 'prop');
[c2 vig2 th2] = rd_findCentersOfMass(roiCoords', map2ROIVals, .2, 'prop');

%% figure
figure
hold on
% plot(map1ROIVals, map2ROIVals, '.k', 'MarkerSize', 20)
scatter(map1ROIVals, map2ROIVals, 20, vig1(:,1)+vig2(:,1), 'filled');
ax = axis;
xlabel('map 1 value')
ylabel('map 2 value')
title(sprintf('%s, %s, %s, %d voxels', view, mapName, roiName, size(roiCoords,2)))
text(ax(1)+.05*(ax(2)-ax(1)), ax(4)-.05*(ax(4)-ax(3)),...
    sprintf('correlation = %.2f', mapValCorr))




