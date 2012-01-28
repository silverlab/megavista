% rd_mrGLMReliability.m

hemi = 2;

load(sprintf('lgnROI%d_multiVoxFigData', hemi))

nConds = 2;

varExp = figData.glm.varianceExplained;
betas = squeeze(figData.glm.betas(:,1:nConds,:));

betas5 = betas(:,varExp>.005);

betas5mean = repmat(mean(betas5,2),1,size(betas5,2));
betas5norm = betas5-betas5mean;

figure
hist(varExp)
xlabel('variance explained')

figure
bar(betas5')
title(sprintf('%s betas varExp>0.5%', figData.roi.name))
legend('M','P')

% figure
% hist(betas5(1,:)-betas5(2,:))
% 
% figure
% bar(betas5norm')
% 
% figure
% hist(betas5norm(1,:)-betas5norm(2,:))