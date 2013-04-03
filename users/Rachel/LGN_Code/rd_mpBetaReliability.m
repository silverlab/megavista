% rd_mpBetaReliability.m
%
% reliability of betaM,P,M-P, and classification across individual scans

%% setup
hemi = 2;
correlationType = 'corrcoef'; % ['corrcoef' (Pearson), 'rankcorr' (Spearman)]

condNames = {'M','P','M-P'};
condProps = [.2 .8 .2];

MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
MPCol = [0 0 0]; % black
colors = {MCol, PCol, MPCol};

saveData = 1;
saveFigs = 1;

%% file i/o
saveFile = sprintf('lgnROI%d_indivScanBetaReliability_%s',hemi, datestr(now,'yyyymmdd'));

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

% mean and std across runs
betaValsMean = squeeze(mean(betaVals,1))'; 
betaValsStd = squeeze(std(betaVals,0,1))';
betaValsSNR = betaValsMean./betaValsStd;

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
%% pairwise correlations (plot matrix)
for iCond = 1:nConds
    figure
    plotmatrix(squeeze(betaVals(:,iCond,:))')
    rd_supertitle(condNames{iCond})
end

%% pairwise correlation values
f(1) = figure;
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
rd_raiseAxis(gca);

%% proportion of voxels assigned to the same group in every run
condToPlot = 3;
prop = condProps(condToPlot);
binodist = binornd(nRuns,prop,nBinoTrials,1)./nRuns;

f(2) = figure;
hold on
group = 1;
[y x] = hist(propRunsVoxInGroup(:,group,condToPlot));
hist(propRunsVoxInGroup(:,group,condToPlot));
binohist = hist(binodist,x);
bar(x, binohist./(nBinoTrials/nVox),'g');
xlabel('prop runs with voxel in group')
ylabel('number of voxels')
legend('data','binomial','Location','best')
title(sprintf('Hemi %d, beta%s, prop = %.2f, group %d', ...
    hemi, condNames{condToPlot}, prop, group));

%% significantly reliable voxels
figure
for iCond = 1:nConds
    sigVoxs = find(reliableVoxs(:,iCond));
    subplot(nConds,1,iCond)
    hold on
    plot(squeeze(propRunsVoxInGroup(:,1,iCond)));
    scatter(sigVoxs,ones(size(sigVoxs)),'.');
    if iCond==nConds
        xlabel('voxel')
    end
    if iCond==2
        ylabel('prop runs with voxel in group 1')
    end
    title(sprintf('Hemi %d, %s', hemi, condNames{iCond})) 
end

%% SNR of beta values across runs
f(3) = figure;
hold on
p = plot(betaValsSNR);
plot([0 nVox],[0 0],'--k');
for iP = 1:numel(p)
    set(p(iP),'Color',colors{iP})
end
xlabel('voxel')
ylabel('SNR of beta value across runs')
legend(condNames)
title(sprintf('Hemi %d',hemi))

%% save data
if saveData
    save(saveFile, 'hemi','correlationType','condNames','condProps',...
            'betas','betaVals','betaValsMean','betaValsStd','betaValsSNR',...
            'runPairCorrs','runPairCorrVals','runPairCorrMeans',...
            'voxsInGroup_dimHeaders','voxsInGroup','propRunsVoxInGroup',...
            'binoConfInts','reliableVoxs')
end

%% save figures
if saveFigs
    figExt{1} = sprintf('MatHist_indivScanBetaCorrelations_%s',...
        correlationType);
    figExt{2} = 'Hist_indivScanBetaMPClassReliability';
    figExt{3} = 'Plot_indivScanBetaSNR';
    for iF = 1:3
        print(f(iF), '-djpeg', sprintf('figures/lgnROI%d%s_%s',...
            hemi, figExt{iF}, datestr(now,'yyyymmdd')));
    end
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