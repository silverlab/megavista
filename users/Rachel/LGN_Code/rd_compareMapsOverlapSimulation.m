% rd_compareMapsOverlapSimulation.m
%
% Question: Given a certain proportion "prop" of voxels to be classified
% into class 1 vs. class 2, how many voxels are expected to overlap if the
% values of the two maps are Gaussian random noise?

%% setup
nVox = 10000;
prop = .5;

%% random map values
map1ROIVals = randn(nVox,1);
map2ROIVals = randn(nVox,1);
roiCoords = randn(3,nVox); % needed for findCentersOfMass, but don't make any difference

mapValCorr = corr(map1ROIVals, map2ROIVals);

%% labeling by class
[c1 vig1 th1] = rd_findCentersOfMass(roiCoords', map1ROIVals, prop, 'prop');
[c2 vig2 th2] = rd_findCentersOfMass(roiCoords', map2ROIVals, prop, 'prop');

%% how many common assignments by chance?
overlap = vig1(:,1)+vig2(:,1);

propCommonClass1 = nnz(overlap==2)/nVox;
propDifferentClass = nnz(overlap==1)/nVox;
propCommonClass2 = nnz(overlap==0)/nVox;

%% display results
fprintf('\n Common Class 1: %.4f', propCommonClass1)
fprintf('\n Common Class 2: %.4f', propCommonClass2)
fprintf('\n Different Class: %.4f\n\n', propDifferentClass)

%% figure
figTitle = 'fake data';

figure
hold on
% plot(map1ROIVals, map2ROIVals, '.k', 'MarkerSize', 20)
scatter(map1ROIVals, map2ROIVals, 20, vig1(:,1)+vig2(:,1), 'filled');
ax = axis;
xlabel('map 1 value')
ylabel('map 2 value')
text(ax(1)+.05*(ax(2)-ax(1)), ax(4)-.05*(ax(4)-ax(3)),...
    sprintf('correlation = %.2f', mapValCorr))
title(figTitle);