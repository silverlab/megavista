function mtrMTDensityComputation(machineDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
threshVec = [2000 1000 500];
%machineDir = /biac2/wandell2/data/conTrack/';

for ss = 1:length(subjVec)
    subjDir = fullfile(machineDir,subjVec{ss});
    fgDir = fullfile(subjDir,'/conTrack/resamp_LMT');
    cd(fgDir);
    mtrComputeManyFiberDensities(subjDir,'paths*100k*.dat',threshVec);
%     fgDir = fullfile(subjDir,'/conTrack/resamp_RMT');
%     cd(fgDir);
%     mtrComputeManyFiberDensities(subjDir,'paths*100k*.dat',threshVec);
end