% rd_mpPCA.m
%
% Principal components analysis on zscore data

%% get data
z = zScores;
% z = superZScores;

figTitle = sprintf('Hemi %d', hemi);
% figTitle = sprintf('Hemi %d, z > %0.1f', hemi, zThresh);

names = condNames;

%% standardize data
nVox = size(z,1);
zStd = std(z);
zs = z./repmat(zStd,nVox,1); % standardized data

%% pca
[coefs,scores,variances,t2] = princomp(zs);

%% more calculations
varianceExplained = variances/sum(variances)

%% if using superthresh voxels, assign scores to correct voxels
voxscores = zeros(length(superthreshVoxs),length(names));
voxscores(superthreshVoxs,:) = scores;

%% plots
% figure
% plot(scores(:,1),scores(:,2),'+')
% xlabel('PC 1')
% ylabel('PC 2')

figure
biplot(double(coefs(:,1:2)),'scores',scores(:,1:2),'varlabels',names);
title(figTitle)

figure
biplot(double(coefs(:,1:3)),'scores',scores(:,1:3),'varlabels',names);
title(figTitle)