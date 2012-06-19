% rd_mpBetaReliability.m
%
% reliability of betaM,P,M-P, and classification across individual scans

%% setup
hemi = 2;
correlationType = 'corrcoef'; % ['corrcoef' (Pearson), 'rankcorr' (Spearman)]

condNames = {'M','P','M-P'};
condProps = [.2 .8 .2];

saveFigs = 0;

%% load data
dataFile = dir(sprintf('lgnROI%d_indivScanData_multiVoxel*', hemi));
if numel(dataFile)~=1
    error('Too many or too few matching data files')
end
load(dataFile.name)

nRuns = numel(uiData);

%% get betas from each run
betas = [];
for iRun = 1:nRuns
    betas(iRun,:,:) = uiData(iRun).mv.glm.betas(:,1:2,:);
end

%% make betaVals to store original betas and all calculated beta vals
betaVals = betas;

% add betaM-P to betaVals as the third condition
betaVals(:,end+1,:) = betas(:,1,:) - betas(:,2,:);
nConds = size(betaVals,2);

%% mean inter-run correlation (mean of pairwise correlations)
runPairCorrs = [];
runPairCorrVals = [];
for iCond = 1:nConds
    switch correlationType
        case 'corrcoef'
            r = corrcoef(squeeze(betaVals(:,iCond,:))'); % [nRuns x nRuns] corrcoef
        case 'rankcorr'
            r = corr(squeeze(betaVals(:,iCond,:))','type','Spearman'); 
        otherwise
            error('correlationType not found')
    end

    % symmetric matrix, so just take the lower triangular values
    rvals = tril(r,-1); % shift by 1 to exclude main diagonal
    
    % remove matrix entries of zero and make 1D
    rvals = rvals(:);
    rvals(rvals==0) = [];
    
    runPairCorrs(:,:,iCond) = r;
    runPairCorrVals(:,iCond) = rvals;
end

runPairCorrMeans = mean(runPairCorrVals);

%% M/P classification based only on beta values
voxsInGroup = [];
voxsInGroup_dimHeaders = {'vox','run','group','cond'};
for iCond = 1:nConds
    prop = condProps(iCond);
    vals = squeeze(betaVals(:,iCond,:))';
    nVox = size(vals,1);
    
    % these lines modified from rd_findCentersOfMass
    valsSorted = sort(vals); % sorts each column
    thresh = valsSorted(round(nVox*(1-prop)),:);
    voxsInGroup(:,:,1,iCond) = vals>repmat(thresh,nVox,1); % [voxs x runs x groups x conds]
    voxsInGroup(:,:,2,iCond) = vals<=repmat(thresh,nVox,1);
end

propRunsVoxInGroup = squeeze(mean(voxsInGroup,2));

% find 95% confidence intervals for binomial distribution
nBinoTrials = 10000;
binoConfInts = [];
for iCond = 1:nConds
    prop = condProps(iCond);
    bino = binornd(nRuns,prop,nBinoTrials,1)./nRuns;
    binoSort = sort(bino);
    binoConfInts(iCond,:) = [binoSort(nBinoTrials*.025) binoSort(nBinoTrials*.975)];
end

% find significantly reliable voxels
reliableVoxs = [];
for iCond = 1:nConds
    reliableVoxs(:,iCond) = propRunsVoxInGroup(:,1,iCond)<binoConfInts(iCond,1) | ...
        propRunsVoxInGroup(:,1,iCond)>binoConfInts(iCond,2);
end

%% figures
% pairwise correlations (plot matrix)
for iCond = 1:nConds
    figure
    plotmatrix(squeeze(betaVals(:,iCond,:))')
    rd_supertitle(condNames{iCond})
end

% pairwise correlation values
f = figure;
for iCond = 1:nConds
    subplot(2,nConds,iCond)
    imagesc(runPairCorrs(:,:,iCond),[-1 1]);
    title(condNames{iCond})
    xlabel('run')
    if iCond==1
        ylabel('run')
    end
    
    subplot(2,nConds,iCond+nConds);
    hist(runPairCorrVals(:,iCond))
    xlim([-1 1])
    ax = axis;
    title(condNames{iCond})
    xlabel('r')
    text(ax(1)*0.9, ax(4)*0.9, sprintf('mean\n%.02f',runPairCorrMeans(iCond)))
    if iCond==1
        ylabel('num pairwise correlations')
    end
end
rd_supertitle(sprintf('Hemi %d, run-to-run beta correlations (%s)', ...
    hemi, correlationType));

% raise title off of subplot titles
titlePos = get(gca,'Position');
titlePos(2) = titlePos(2)*1.27;
set(gca,'Position',titlePos);

% significantly reliable voxels
figure
for iCond = 1:nConds
    subplot(nConds,1,iCond)
    hold on
    plot(squeeze(propRunsVoxInGroup(:,1,iCond)));
    scatter(1:nVox,reliableVoxs(:,iCond),'.');
end

%% save figures
if saveFigs
    figName = sprintf('figures/lgnROI%dMatHist_indivScanBetaCorrelations_%s_%s', ...
        hemi, correlationType, datestr(now,'yyyymmdd'));
    print(f, '-djpeg', figName);
end


%% old code that works but isn't that revealing
% %% rank order of beta values for plotting
% % get rank order for mean of betaM and betaP
% betaValsMean = squeeze(mean(betaVals,1));
% [betaValsMeanS, order] = sort(betaValsMean,2);
% 
% %% figures
% 
% % each run sorted by rank order of mean
% for iCond = 1:nConds
%     figure
%     subplot(1,2,1)
%     plot(squeeze(betaVals(:,iCond,order(iCond,:)))','.')
%     axis square
%     subplot(1,2,2)
%     plot(squeeze(betaVals(:,iCond,:))','.')
%     axis square
%     rd_supertitle(condNames{iCond})
% end