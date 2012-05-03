% rd_mpBetaReliability.m

hemi = 1;

dataFile = dir(sprintf('lgnROI%d_indivScanData_multiVoxel*', hemi));
if numel(dataFile)~=1
    error('Too many or too few matching data files')
end
load(dataFile.name)

condNames = {'M','P'};
nRuns = numel(uiData);

for iRun = 1:nRuns
    betas(iRun,:,:) = uiData(iRun).mv.glm.betas(:,1:2,:);
end
nConds = size(betas,2);

betasMPDiff = squeeze(betas(:,1,:) - betas(:,2,:));

betasMean = squeeze(mean(betas,1));
[betasMeanS, order] = sort(betasMean,2);

betasMPDiffMean = mean(betasMPDiff,1);
[betasMPDiffMeanS, mpDiffOrder] = sort(betasMPDiffMean,2);

for iCond = 1:nConds
    figure
    subplot(1,2,1)
    plot(squeeze(betas(:,iCond,order(iCond,:)))','.')
    axis square
    subplot(1,2,2)
    plot(squeeze(betas(:,iCond,:))','.')
    axis square
    rd_supertitle(condNames{iCond})
end

figure
subplot(1,2,1)
plot(betasMPDiff(:,mpDiffOrder)','.')
axis square
subplot(1,2,2)
plot(betasMPDiff','.')
axis square
rd_supertitle('M-P')

for iCond = 1:nConds
    figure
    plotmatrix(squeeze(betas(:,iCond,:))')
    rd_supertitle(condNames{iCond})
end

figure
plotmatrix(betasMPDiff')
rd_supertitle('M-P')

