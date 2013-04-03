% rd_mcComparison_mcflirtSPM.m

hemi = 2;

fileName = sprintf('lgnROI%d_mcflirt_vs_spm_f.mat', hemi);

load(fileName)

condNames = {'M','P'};
delays = f_mcflirt.hemoDelays;
nDelays = numel(delays);

f1 = figure;
for iDelay = 1:nDelays
    subplot(1,nDelays,iDelay)
    hold on
    plot(f_mcflirt.F.overall(:,iDelay), f_spm.F.overall(:,iDelay),'k.','MarkerSize',10)
    plot([0 40],[0 40],'k')
    xlabel('mcflirt')
    ylabel('spm')
    title(sprintf('Delay = %d', delays(iDelay)))
end
rd_supertitle(sprintf('Overall F, hemi %d', hemi))

for iCond = 1:2
    f2(iCond) = figure;
    for iDelay = 1:nDelays
        subplot(1,nDelays,iDelay)
        hold on
        plot(f_mcflirt.F.cond(:,iCond,iDelay), f_spm.F.cond(:,iCond,iDelay),'k.','MarkerSize',10)
        plot([0 50],[0 50],'k')
        xlabel('mcflirt')
        ylabel('spm')
        title(sprintf('Delay = %d', delays(iDelay)))
    end
    rd_supertitle(sprintf('Overall F, hemi %d, %s', hemi, condNames{iCond}))
end

% % commands used to make f_mcflirt and f_spm (for record)
% roi2_f_spm = load('lgnROI2_fTests_20120328')
% cd ../../../RD_20120205_n/ROIAnalysis/ROIX01/
% roi2_f_mcflirt = load('lgnROI2_fTests_20120216')
% f_mcflirt = roi2_f_mcflirt;
% f_spm = roi2_f_spm
% f_spm= load ('ROIX01/lgnROI1_fTests_20120328.mat')
% f_mcflirt = load('../../RD_20120205_n/ROIAnalysis/ROIX01/lgnROI1_fTests_20120216.mat')
