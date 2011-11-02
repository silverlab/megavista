function mtrMTDensityComparisons(machineDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
threshVec = [1000];
fgDensitySrcFileBase = 'paths_100k_5k_kSmooth_18_kLength_-2_kMidSD_0.175';

for ss = 1:length(subjVec)
    subjDir = fullfile(machineDir, subjVec{ss});
    fgDir = fullfile(subjDir, '/conTrack/resamp_LMT');
    cd(fgDir);
    for tt = threshVec
        strThresh = ['_thresh_' num2str(tt)];
        fgDensitySrcFile = [fgDensitySrcFileBase strThresh '_fd_image.nii.gz'];
        mtrCompareDensities(subjDir, fgDensitySrcFile, ['*' strThresh], [], ['cc' strThresh '.mat']);
    end
    fgDir = fullfile(subjDir, '/conTrack/resamp_RMT');
    cd(fgDir);
    for tt = threshVec
        strThresh = ['_thresh_' num2str(tt)];
        fgDensitySrcFile = [fgDensitySrcFileBase strThresh '_fd_image.nii.gz'];
        mtrCompareDensities(subjDir, fgDensitySrcFile, ['*' strThresh], [], ['cc' strThresh '.mat']);
    end
end

