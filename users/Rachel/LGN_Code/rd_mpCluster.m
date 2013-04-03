% rd_mpCluster.m

%% setup
hemi = 2;
betaCoefs = [.5 -.5];
mapName = 'betaM-P';
thresh = .01;
varExpMultiplier = 800;

saveFigs = 1;

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
xlabel('beta M')
ylabel('beta P')
title(sprintf('Hemi %d voxels, color = varExp', hemi))
colorbar

f1 = figure;
scatter(betas(:,1), betas(:,2), varExp*varExpMultiplier, betas*betaCoefs', 'filled')
% scatter(betas(:,1), betas(:,2), varExp*varExpMultiplier, 'k', 'filled')
xlabel('beta M')
ylabel('beta P')
title(sprintf('Hemi %d voxels, size = varExp, color = %s', hemi, mapName))
% colormap(flipud(lbmap(64,'RedBlue')))
colorbar

%% k-means (all voxels)
nClusters = 3;
idx = kmeans(betas,nClusters);

f2 = figure;
scatter(betas(:,1),betas(:,2),30,idx,'filled')
xlabel('beta M')
ylabel('beta P')
title(sprintf('Hemi %d voxels, color = kmeans class', hemi))

%% k-means with threshold
idx = kmeans(betas(varExp>thresh,:),2);

figure
scatter(betas(varExp>thresh,1),betas(varExp>thresh,2),30,idx,'filled')
xlabel('beta M')
ylabel('beta P')
title(sprintf('Hemi %d voxels, varThresh = %.03f, color = kmeans class', hemi, thresh))

%% save figs
fig1SavePath = sprintf('figures/%sScatter_betaMvsP_varExp_%s_%s', fileBase, mapName, datestr(now,'yyyymmdd'));
fig2SavePath = sprintf('figures/%sScatter_betaMvsP_kmeans%d_%s', fileBase, nClusters, datestr(now,'yyyymmdd'));

if saveFigs
%     print(f1,'-djpeg',sprintf(fig1SavePath));
    print(f2,'-djpeg',sprintf(fig2SavePath));
end


