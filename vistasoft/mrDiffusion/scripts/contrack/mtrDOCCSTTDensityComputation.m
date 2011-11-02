subjVec = {'ss040804','mho040625','bg040719','md040714'};

for ss = 1:length(subjVec)
    subjDir = ['/teal/scr1/dti/sisr/' subjVec{ss}];
    fgDir = [subjDir '/fibers'];
    cd(fgDir);
    mtrComputeManyFiberDensities(subjDir,'paths*.dat');
end