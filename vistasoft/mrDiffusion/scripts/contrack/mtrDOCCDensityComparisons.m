
%subjVec = {'ss040804','mho040625','bg040719','md040714'};
subjVec = {'bg040719'};
threshVec = [1000];
fgDensitySrcFileBase = 'paths_100k_5k_kSmooth_18_kLength_-2_kMidSD_0.175';

for ss = 1:length(subjVec)
    subjDir = ['/teal/scr1/dti/sisr/' subjVec{ss}];
    fgDir = [subjDir '/conTrack/resamp_LDOCC'];
    cd(fgDir);
    for tt = threshVec
        strThresh = ['_thresh_' num2str(tt)];
        fgDensitySrcFile = [fgDensitySrcFileBase strThresh '_fd_image.nii.gz'];
        mtrCompareDensities(subjDir, fgDensitySrcFile, ['*' strThresh], [], ['cc_-2' strThresh '.mat']);
    end
    fgDir = [subjDir '/conTrack/resamp_RDOCC'];
    cd(fgDir);
    for tt = threshVec
        strThresh = ['_thresh_' num2str(tt)];
        fgDensitySrcFile = [fgDensitySrcFileBase strThresh '_fd_image.nii.gz'];
        mtrCompareDensities(subjDir, fgDensitySrcFile, ['*' strThresh], [], ['cc_-2' strThresh '.mat']);
    end
end

