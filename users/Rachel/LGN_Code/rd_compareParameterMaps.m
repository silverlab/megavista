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
classMapName = 'MPClass'; % if no class map, set to []
subjectID = 'AV';
roiName = 'ROI101-i3T17T';
prop = .2;

% set map idxs in case there are multiple scans in this data type
map1Idx = 1;
map2Idx = 1; % 2 for RD 7T

saveData = 0;
saveFigures = 0;

%% file i/o
studyDir = '/Volumes/Plata1/LGN/Scans';

% session1Dir = '3T/AV_20111117_session/AV_20111117_n';
% session2Dir = '3T/AV_20111128_session/AV_20111128_n';

session1Dir = '3T/AV_20111117_session/AV_20111117_n';
session2Dir = '7T/AV_20111213_session/AV_20111213';

% session1Dir = '3T/AV_20111128_session/AV_20111128_n';
% session2Dir = '7T/AV_20111213_session/AV_20111213';

% session1Dir = '3T/RD_20120205_session/RD_20120205_n';
% session2Dir = '7T/RD_20111214_session/RD_20111214';

% session1Dir = '7T/KS_20111212_session/KS_20111212_15mm';
% session2Dir = '7T/KS_20111214_session/KS_20111214';

viewCoordsExtension = sprintf('%s/coords.mat', view);
mapExtension = sprintf('%s/%s/%s.mat', view, dataType, mapName);
roiExtension = sprintf('%s/ROIs/%s.mat', view, roiName);

view1CoordsPath = sprintf('%s/%s/%s', studyDir, session1Dir, viewCoordsExtension);
view2CoordsPath = sprintf('%s/%s/%s', studyDir, session2Dir, viewCoordsExtension);
map1Path = sprintf('%s/%s/%s', studyDir, session1Dir, mapExtension);
map2Path = sprintf('%s/%s/%s', studyDir, session2Dir, mapExtension);
roiPath = sprintf('%s/%s/%s', studyDir, session1Dir, roiExtension);

if ~isempty(classMapName)
    classMapExtension = sprintf('%s/%s/%s.mat', view, dataType, classMapName);
    classMap1Path = sprintf('%s/%s/%s', studyDir, session1Dir, classMapExtension);
    classMap2Path = sprintf('%s/%s/%s', studyDir, session2Dir, classMapExtension);
end

% file out
saveDir = '/Volumes/Plata1/LGN/Group_Analyses';
analysisExtension = sprintf('crossSessionComparison_%s_%s_%s_prop%d', ...
    subjectID, roiName, mapName, prop*100);
analysisSavePath = sprintf('%s/%s_%s.mat', saveDir, analysisExtension, datestr(now,'yyyymmdd'));

%% load coords, maps, roi
view1Coords = load(view1CoordsPath);
view1Coords = view1Coords.coords;
view2Coords = load(view2CoordsPath);
view2Coords = view2Coords.coords;
map1 = load(map1Path);
map2 = load(map2Path);
roi = load(roiPath);

if ~isempty(classMapName)
    classMap1 = load(classMap1Path);
    classMap2 = load(classMap2Path);
end

%% get map data and ROI coords
map1Data = map1.map{map1Idx};
map2Data = map2.map{map2Idx};

roiCoords = roi.ROI.coords;
nVox = size(roiCoords,2);

if ~isempty(classMapName)
    classMap1Data = classMap1.map{map1Idx};
    classMap2Data = classMap2.map{map2Idx};
end

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

if ~isempty(classMapName)
    classMap1ROIVals = classMap1Data(inROIMap1)';
    classMap2ROIVals = classMap2Data(inROIMap2)';
else
    classMap1ROIVals = [];
    classMap2ROIVals = [];
end

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
% from Volume assignments
volumeClassOverlap = vig1(:,1)+vig2(:,1);

propCommonVolClass1 = nnz(volumeClassOverlap==2)/nVox;
propDifferentVolClass = nnz(volumeClassOverlap==1)/nVox;
propCommonVolClass2 = nnz(volumeClassOverlap==0)/nVox;

volClassProps = [propCommonVolClass1 propCommonVolClass2 propDifferentVolClass];
volClassPropsHeaders = {'common1','common2','different'};

if ~isempty(classMapName)
    classMapOverlap = classMap1ROIVals + classMap2ROIVals;
    classMapProduct = classMap1ROIVals.*classMap2ROIVals;
    
    propCommonIPClass1 = nnz(classMapOverlap==2)/nVox;
    propDifferentIPClass = nnz(classMapOverlap==0 & classMapProduct==-1)/nVox;
    propCommonIPClass2 = nnz(classMapOverlap==-2)/nVox;
    propInOnlyOneIPMap = nnz(classMapOverlap==1 | classMapOverlap==-1)/nVox;
    propInNeitherIPMap = nnz(classMapOverlap==0 & classMapProduct==0)/nVox;
end

ipClassProps = [propCommonIPClass1 propCommonIPClass2 propDifferentIPClass propInOnlyOneIPMap propInNeitherIPMap];
ipClassPropsHeaders = {'common1','common2','different','oneMap','neither'};

%% display common class results
fprintf('\nVolume class overlap:\n')
fprintf('\n Common Class 1: %.4f', propCommonVolClass1)
fprintf('\n Common Class 2: %.4f', propCommonVolClass2)
fprintf('\n Different Class: %.4f\n\n', propDifferentVolClass)

if ~isempty(classMapName)
    fprintf('\nInplane class overlap:\n')
    fprintf('\n Common Class 1: %.4f', propCommonIPClass1)
    fprintf('\n Common Class 2: %.4f', propCommonIPClass2)
    fprintf('\n Different Class: %.4f', propDifferentIPClass)
    fprintf('\n Classified in only one map: %.4f', propInOnlyOneIPMap)
    fprintf('\n Classified in neither map: %.4f\n\n', propInNeitherIPMap)
end

%% figure 1
figTitle = sprintf('%s %s, %s %s, %d voxels', subjectID, roiName, view, mapName, size(roiCoords,2));

figNames{1} = 'correlationWithConfInt';
f(1) = figure;
subplot('position',[.1 .12 .5 .75])
hold on
plot(map1ROIVals, map2ROIVals, '.k', 'MarkerSize', 20)
ax = axis;
xlabel('map 1 value')
ylabel('map 2 value')
text(ax(1)+.05*(ax(2)-ax(1)), ax(4)+.03*(ax(4)-ax(3)),...
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

%% figure 2
chancePoints = [.0387 .6387 .3226];

figNames{2} = 'correlationWithClassification';
f(2) = figure('Position',[0 0 800 600]);
subplot(2,2,1)
scatter(map1ROIVals, map2ROIVals, 20, volumeClassOverlap, 'filled');
xlabel('map 1 value')
ylabel('map 2 value')
title('Volume Classes')

subplot(2,2,2)
scatter(map1ROIVals, map2ROIVals, 20, classMapOverlap, 'filled');
xlabel('map 1 value')
ylabel('map 2 value')
title('Inplane Classes')

subplot(2,2,3)
hold on
bar(volClassProps)
plot(1:3, chancePoints, '.r', 'MarkerSize', 10)
ylim([0 1])
set(gca,'XTick',1:length(volClassProps))
set(gca,'XTickLabel',volClassPropsHeaders)
ylabel('proportion of voxels')

subplot(2,2,4)
hold on
bar(ipClassProps)
plot(1:3, chancePoints*sum(ipClassProps(1:3)), '.r', 'MarkerSize', 10)
ylim([0 1])
set(gca,'XTick',1:length(ipClassProps))
set(gca,'XTickLabel',ipClassPropsHeaders)
ylabel('proportion of voxels')

rd_supertitle(figTitle);
rd_raiseAxis(gca);

%% save data
if saveData
   save(analysisSavePath,'view', 'dataType', 'mapName', 'classMapName',...
       'subjectID','roiName','prop', 'map1Idx','map2Idx',...
       'map1ROIVals','map2ROIVals','classMap1ROIVals','classMap2ROIVals',...
       'mapValCorr','corrConf','volClassProps','volClassPropsHeaders',...
       'ipClassProps','ipClassPropsHeaders')
end

%% save figures
if saveFigures
    for iF = 1:numel(f)
        figName = figNames{iF};
        figSavePath = sprintf('%s/figures/%s_%s_%s', ...
            saveDir, analysisExtension, figName, datestr(now,'yyyymmdd'));
        print(f(iF), '-djpeg', figSavePath)
    end
end

