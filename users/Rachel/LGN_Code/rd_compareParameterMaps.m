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
subjectID = 'RD';
roiName = 'ROI101-i3T7T';
prop = .2;

% set map idxs in case there are multiple scans in this data type
map1Idx = 1;
map2Idx = 2; % 2 for RD 7T

%% file i/o
studyDir = '/Volumes/Plata1/LGN/Scans';

session1Dir = '3T/RD_20120205_session/RD_20120205_n';
session2Dir = '7T/RD_20111214_session/RD_20111214';

% session1Dir = '3T/AV_20111117_session/AV_20111117_n';
% session2Dir = '3T/AV_20111128_session/AV_20111128_n';

% session1Dir = '3T/AV_20111117_session/AV_20111117_n';
% session2Dir = '7T/AV_20111213_session/AV_20111213';

% session1Dir = '3T/AV_20111128_session/AV_20111128_n';
% session2Dir = '7T/AV_20111213_session/AV_20111213';

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
nVox = size(roiCoords,2);

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

%% compute 95% confidence interval on the correlation
corrDist = bootstrp(10000, @(x1,x2) corr(x1,x2), map1ROIVals', map2ROIVals');
corrConf = prctile(corrDist,[2.5 97.5]);
fprintf('CI (95%%) = [%.3f %.3f]\n', corrConf);

%% labeling by m/p class
% Note: this is class as determined from Volume voxels in this new common
% ROI -- not the original Inplane-based classification in session-specific
% ROIs.
[c1 vig1 th1] = rd_findCentersOfMass(roiCoords', map1ROIVals, prop, 'prop');
[c2 vig2 th2] = rd_findCentersOfMass(roiCoords', map2ROIVals, prop, 'prop');

%% how many common class assignments?
overlap = vig1(:,1)+vig2(:,1);

propCommonClass1 = nnz(overlap==2)/nVox;
propDifferentClass = nnz(overlap==1)/nVox;
propCommonClass2 = nnz(overlap==0)/nVox;

%% display common class results
fprintf('\n Common Class 1: %.4f', propCommonClass1)
fprintf('\n Common Class 2: %.4f', propCommonClass2)
fprintf('\n Different Class: %.4f\n\n', propDifferentClass)

%% figure
figTitle = sprintf('%s %s, %s %s, %d voxels', subjectID, roiName, view, mapName, size(roiCoords,2));

figure
subplot('position',[.1 .12 .5 .75])
hold on
% plot(map1ROIVals, map2ROIVals, '.k', 'MarkerSize', 20)
scatter(map1ROIVals, map2ROIVals, 20, overlap, 'filled');
ax = axis;
xlabel('map 1 value')
ylabel('map 2 value')
text(ax(1)+.05*(ax(2)-ax(1)), ax(4)-.05*(ax(4)-ax(3)),...
    sprintf('correlation = %.2f', mapValCorr))

subplot('position',[.75 .12 .2 .75])
hold on
bar(0, mapValCorr)
errorbar(0, mapValCorr, mapValCorr-corrConf(1), corrConf(2)-mapValCorr, ...
    'r','LineWidth',2)
xlim([-.8 .8])
set(gca,'XTick',[])
ylabel('correlation with 95% confidence interval')

rd_supertitle(figTitle);
