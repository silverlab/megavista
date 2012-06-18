% rd_mpBetaReliability.m
%
% reliability of betaM,P,M-P, and classification across individual scans

%% setup
hemi = 1;
correlationType = 'corrcoef'; % ['corrcoef','rankcorr']

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

betas(:,3,:) = betasMPDiff;

%% rank order of beta values for plotting
% get rank order for mean of betaM and betaP
betasMean = squeeze(mean(betas,1));
[betasMeanS, order] = sort(betasMean,2);

% get rank order for mean of betaM-P
betasMPDiffMean = mean(betasMPDiff,1);
[betasMPDiffMeanS, mpDiffOrder] = sort(betasMPDiffMean,2);

%% mean inter-run correlation (mean of pairwise correlations)
for iCond = 1:nConds
    switch correlationType
        case 'corrcoef'
            r = corrcoef(squeeze(betas(:,iCond,:))'); % [nRuns x nRuns] corrcoef
        case 'rankcorr'
            r = corr(squeeze(betas(:,iCond,:))'); 
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

switch correlationType
    case 'corrcoef'
        r = corrcoef(squeeze(betas(:,iCond,:))'); % [nRuns x nRuns] corrcoef
    case 'rankcorr'
        r = corr(squeeze(betas(:,iCond,:))');
    otherwise
        error('correlationType not found')
end


%% figures
% each run sorted by rank order of mean
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

% pairwise correlations
for iCond = 1:nConds
    figure
    plotmatrix(squeeze(betas(:,iCond,:))')
    rd_supertitle(condNames{iCond})
end

figure
plotmatrix(betasMPDiff')
rd_supertitle('M-P')

