
%subjVec = {'ss040804','mho040625','bg040719','md040714'};
subjVec = {'ss040804','mho040625'};
threshVec = [2000 1000 500];
fgDensitySrcFileBase = 'paths_100k_5k_kSmooth_18_kLength_-2_kMidSD_0.175.dat';

idFile = ['id_' fgDensitySrcFileBase];
scoreFile = ['score_' fgDensitySrcFileBase];

for ss = 1:length(subjVec)
    subjDir = ['/teal/scr1/dti/sisr/' subjVec{ss}];
    fgDir = [subjDir '/conTrack/ranktest_LDOCC'];
    cd(fgDir);
    [rhoS, rhoK, pvalS, pvalK, overlapVec, pdbIDFiles, threshVec] = mtrComparePDBRanks(idFile,scoreFile,'id_*.dat','score_*.dat',threshVec,0);
    save('rankTestSummary.mat','rhoS', 'rhoK', 'pvalS', 'pvalK', 'overlapVec', 'pdbIDFiles', 'threshVec');
    disp(['Saved rankTestSummary.mat for ' subjVec{ss} ' LDOCC']);
    
    fgDir = [subjDir '/conTrack/ranktest_RDOCC'];
    cd(fgDir);
    [rhoS, rhoK, pvalS, pvalK, overlapVec, pdbIDFiles, threshVec] = mtrComparePDBRanks(idFile,scoreFile,'id_*.dat','score_*.dat',threshVec,0);
    save('rankTestSummary.mat','rhoS', 'rhoK', 'pvalS', 'pvalK', 'overlapVec', 'pdbIDFiles', 'threshVec');
    disp(['Saved rankTestSummary.mat for ' subjVec{ss} ' RDOCC']);
    
end