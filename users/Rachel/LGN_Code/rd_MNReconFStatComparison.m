% rd_MNReconFStatComparison.m

% from inside MN orig ROIX02 folder ...


for iRun = 1:5
    %% Load data
    dataMN1_hemi1 = load(sprintf('lgnROI1_fTests_run%02d_20130315', iRun));
    dataMN1_hemi2 = load(sprintf('lgnROI2_fTests_run%02d_20130315', iRun));
    
    dataMN2_hemi1 = load(sprintf('../../../../MN_20120806_recon2_flipLR/ROIAnalysis/ROIX01/lgnROI1_fTests_run%02d_20130315.mat', iRun));
    dataMN2_hemi2 = load(sprintf('../../../../MN_20120806_recon2_flipLR/ROIAnalysis/ROIX01/lgnROI2_fTests_run%02d_20130315.mat', iRun));
    
    %% Overall mean
    % left hemisphere (dims = [subject delay hemi])
    f.overallMean(1,:,iRun,1) = dataMN1_hemi2.F.overallMean; % hemi 2 is left
    f.overallMean(2,:,iRun,1) = dataMN2_hemi1.F.overallMean; % hemi 1 is left
    
    % right hemisphere
    f.overallMean(1,:,iRun,2) = dataMN1_hemi1.F.overallMean; % hemi 1 is right
    f.overallMean(2,:,iRun,2) = dataMN2_hemi2.F.overallMean; % hemi 2 is right
end

%% Let's skip this -- too much detail
% %% Various measures that are 4x2 in fTests data
% measures = {'condMean','condStd','condThreshedMean','condThreshedStd'};
% for iM = 1:length(measures)
%     m = measures{iM};
%     % left hemisphere (dims = [delay cond subject hemi])
%     f.(m)(:,:,1,1) = dataMN1_hemi2.F.(m); % hemi 2 is left
%     f.(m)(:,:,2,1) = dataMN2_hemi1.F.(m); % hemi 1 is left
% 
%     % right hemisphere
%     f.(m)(:,:,1,2) = dataMN1_hemi1.F.(m); % hemi 1 is right
%     f.(m)(:,:,2,2) = dataMN2_hemi2.F.(m); % hemi 2 is right
% end

%% Take mean across delays
% dims = [subject run hemi]
f.overallMeanMean = squeeze(mean(f.overallMean,2));

%% Plot figs
% for a single run, at all delays
figure
iRun = 1;
for iHemi = 1:2
    subplot(1,2,iHemi)
    plot(f.overallMean(:,:,iRun,iHemi)');
    xlabel('delay (TR)')
    ylabel('F statistic')
    if iHemi==1
        legend('orig','recon','Location','Best')
    end
end

% averaged across delays
figure
for iHemi = 1:2
    subplot(1,2,iHemi)
    bar(f.overallMeanMean(:,:,iHemi)');
    xlabel('run')
    ylabel('F statistic (averaged across delays 0-3)')
    title(sprintf('Hemi %d', iHemi))
    if iHemi==1
        legend('orig','recon','Location','Best')
    end
end

% Let's skip this -- too much detail
% figure
% iCond = 1;
% for iHemi = 1:2
%     subplot(1,2,iHemi)
%     errorbar(squeeze(f.condMean(:,iCond,:,iHemi)), squeeze(f.condStd(:,iCond,:,iHemi)));
%     if iHemi==1
%         legend('orig','recon','Location','Best')
%     end
% end