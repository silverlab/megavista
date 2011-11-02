
subjVec = {'ss040804','mho040625','bg040719','md040714'};


for ss = 1:length(subjVec)
    subjDir = ['/teal/scr1/dti/sisr/' subjVec{ss}];
    fgDir = [subjDir '/fibers'];
    cd(fgDir);
    
    disp(['Clipping RDOCC STT fibers for ' subjVec{ss} ' ...']);
    f = dir('*RDOCC*CC_FA*RV3AB7d*.mat');
    fgInFile = f.name;
    mtrClipFiberGroupToROIs(fgInFile,fullfile(subjDir,'dt6.mat'),fullfile(subjDir,'ROIs/CC_FA.mat'),fullfile(subjDir,'ROIs/RV3AB7d.mat'),fullfile(subjDir,'bin/wmMask.nii.gz'),'paths_STT_RDOCC.mat');
    mtrExportFiberGroupToMetrotrac('paths_STT_RDOCC.dat','paths_STT_RDOCC.mat', fullfile(subjDir,'bin/fa.nii.gz'));
  
    disp(['Clipping LDOCC STT fibers for ' subjVec{ss} ' ...']);
    f = dir('*LDOCC*CC_FA*LV3AB7d*.mat');
    fgInFile = f.name;
    mtrClipFiberGroupToROIs(fgInFile,fullfile(subjDir,'dt6.mat'),fullfile(subjDir,'ROIs/CC_FA.mat'),fullfile(subjDir,'ROIs/LV3AB7d.mat'),fullfile(subjDir,'bin/wmMask.nii.gz'),'paths_STT_LDOCC.mat');
    mtrExportFiberGroupToMetrotrac('paths_STT_LDOCC.dat','paths_STT_LDOCC.mat', fullfile(subjDir,'bin/fa.nii.gz'));
 
end

