function mtrDOCCCompareHist2STT(machineDir,imageDir)
subjVec = {'ss040804','mho040625','bg040719','md040714'};
fgSrcFile = 'paths_100k_5k_kSmooth_18_kLength_-2_kMidSD_0.175.dat';
ctThresh = 4/5;
sttThresh = 0.05;
% %machineDir = '/teal/scr1/dti/sisr/';
% machineDir = 'c:/cygwin/home/sherbond/images/';
bSaveImages = 1;

for ss = 1:length(subjVec)
    subjDir = [machineDir subjVec{ss}];
    
    fgDir = [subjDir '/conTrack/resamp_LDOCC'];
    cd(fgDir);
    figure;
    subplot(1,2,1); mtrPDBScoreHist(fgSrcFile,'kv-',ctThresh,'../../dt6.mat'); hold on;
    mtrPDBScoreHist('../../fibers/paths_STT_LDOCC.dat','ko--',sttThresh,'../../dt6.mat'); hold off;
    axis([-50 150 0 8]);
    %legend({'conTrack','STT'});
    %title(['Hist of STT (yellow) and CT (blue) for LDOCC of ' subjVec{ss}]);
    
    
    fgDir = [subjDir '/conTrack/resamp_RDOCC'];
    cd(fgDir);
    subplot(1,2,2); mtrPDBScoreHist(fgSrcFile,'kv-',ctThresh,'../../dt6.mat'); hold on;
    mtrPDBScoreHist('../../fibers/paths_STT_RDOCC.dat','ko--',sttThresh,'../../dt6.mat'); hold off;
    axis([-50 150 0 8]);
    %legend({'conTrack','STT'});
    %title(['Hist of STT (yellow) and CT (blue) for RDOCC of ' subjVec{ss}]);
    
    set(gcf,'Position',[410   597   672   270]);    
    if bSaveImages
        figFilename = fullfile(subjDir,imageDir,['histScoreCTandSTT.png'])
        set(gcf,'PaperPositionMode','auto');
        print('-dpng', figFilename);
    end
end