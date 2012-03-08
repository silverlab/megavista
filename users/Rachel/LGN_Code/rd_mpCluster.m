% rd_mpCluster.m

%% setup
hemi = 2;
betaCoefs = [.5 -.5];

%% file i/o
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);

%% load data
load(loadPath)

varExp = figData.glm.varianceExplained;
betas = squeeze(figData.glm.betas(:,1:2,:))';

%% plot betaM vs betaP
figure
scatter(betas(:,1),betas(:,2),30,varExp,'filled')

figure
scatter(betas(:,1), betas(:,2), varExp*800, betas*betaCoefs', 'filled')

%% k-means (all voxels)
idx = kmeans(betas,2);

figure
scatter(betas(:,1),betas(:,2),30,idx,'filled')

%% k-means with threshold
thresh = .01;
idx = kmeans(betas(varExp>thresh,:),2);

figure
scatter(betas(varExp>thresh,1),betas(varExp>thresh,2),30,idx,'filled')
