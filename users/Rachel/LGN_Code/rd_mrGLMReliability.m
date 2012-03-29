% rd_mrGLMReliability.m

%% Setup
hemi = 2;

nConds = 2;
varThresh = 0.005; % eg. 0.005

saveFigs = 1;

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);

%% Load data
load(loadPath)

%% Get thresholded betas
varExp = figData.glm.varianceExplained;
betas = squeeze(figData.glm.betas(:,1:nConds,:));

betasThreshed = betas(:,varExp>varThresh);

%% Plot figs
f1 = figure;
hist(varExp)
xlabel('variance explained')
ylabel('number of voxels')
title(sprintf('Hemi %d', hemi))

f2 = figure;
bar(betasThreshed')
xlabel('voxel number')
if varThresh == 0
   title(sprintf('Hemi %d betas', hemi)) 
else
    title(sprintf('Hemi %d betas, varExp > %.1f%%', hemi, varThresh*100))
end
legend('M','P')

% want M to be red, P to be blue
y = get(gcf,'colormap');
redbluemap = y([end 1],:);
colormap(redbluemap);

%% Save figs
varPlotSavePath = sprintf('%s%s_%s_%s', fileBase, 'Hist', 'varExp', datestr(now,'yyyymmdd'));
betasPlotSavePath = sprintf('%s%s_%s%03d_%s', fileBase, 'Bars', 'betas_varThresh', round(varThresh*1000), datestr(now,'yyyymmdd'));

if saveFigs
    print(f1,'-djpeg',sprintf('figures/%s', varPlotSavePath));
    print(f2,'-djpeg',sprintf('figures/%s', betasPlotSavePath));
end

%% Old
% betas5mean = repmat(mean(betas5,2),1,size(betas5,2));
% betas5norm = betas5-betas5mean;
%
% figure
% hist(betas5(1,:)-betas5(2,:))
% 
% figure
% bar(betas5norm')
% 
% figure
% hist(betas5norm(1,:)-betas5norm(2,:))