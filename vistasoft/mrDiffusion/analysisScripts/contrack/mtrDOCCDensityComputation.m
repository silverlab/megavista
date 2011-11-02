function mtrDOCCDensityComputation(machineDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
threshVec = [5000 2000 1000 500];
%machineDir = /biac2/wandell2/data/conTrack/';

for ss = 1:length(subjVec)
    subjDir = fullfile(machineDir,subjVec{ss});
    fgDir = fullfile(subjDir,'/conTrack/resamp_LDOCC');
    cd(fgDir);
    mtrComputeManyFiberDensities(subjDir,'paths*100k*',threshVec);
    fgDir = fullfile(subjDir,'/conTrack/resamp_RDOCC');
    cd(fgDir);
    mtrComputeManyFiberDensities(subjDir,'paths*100k*',threshVec);
end