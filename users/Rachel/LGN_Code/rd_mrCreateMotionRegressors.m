% rd_mrCreateMotionRegressors.m

% get the motion parameters at each TR from the saved .par files in the
% nifti directory
% get the frames to keep and discard from mrInit2_params

scans = 2:9;
niftiDir = 'AV_20111117_n_nifti';
load mrInit2_params

motionRegressors = [];
for iScan = 1:numel(scans)
    scan = scans(iScan);
    
    motionFile = sprintf('%s/epi%02d_mp_mcf.par', niftiDir, scan);
    moPars = load(motionFile);
    
    keepFrames = params.keepFrames(scan,:);
    if keepFrames(2)==-1
        moPars = moPars(keepFrames(1)+1:end,:);
    else
        moPars = moPars(keepFrames(1)+1:sum(keepFrames),:);
    end
    
    motionRegressors = [motionRegressors; moPars];
end

fprintf('\nMotion regressors size = [%d %d]\n', size(motionRegressors))

figure
plot(motionRegressors)