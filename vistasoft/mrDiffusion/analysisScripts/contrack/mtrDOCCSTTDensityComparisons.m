
subjVec = {'ss040804','mho040625','bg040719','md040714'};
threshVec = [1000];
bCompare2D = 0;

for ss = 1:length(subjVec)
    subjDir = ['/teal/scr1/dti/sisr/' subjVec{ss}]; 
    
    
    % Create STT density files
    cd([subjDir '/fibers']);
    fR = dir(fullfile(subjDir,'fibers','paths*STT_RDOCC*fd_image.nii.gz'));
    fL = dir(fullfile(subjDir,'fibers','paths*STT_LDOCC*fd_image.nii.gz'));
    if( isempty(fR) || isempty(fL) )
        mtrComputeManyFiberDensities(subjDir, 'paths_STT_*DOCC.dat');
    end
    
    % Get slice coordinates from CC ROI
    cd(subjDir);
    dt6 = load('dt6.mat');
    cd([subjDir '/ROIs']);
    roi = dtiReadRoi('CC_FA.mat');
    M = eye(4); M(1:3,1:3) = diag(dt6.mmPerVox); 
    xformT1ToAcPc = dt6.xformToAcPc;
    xformT1ToAcPc(1,1) = xformT1ToAcPc(1,1) / dt6.mmPerVox(1);
    xformT1ToAcPc(2,2) = xformT1ToAcPc(2,2) / dt6.mmPerVox(2);
    xformT1ToAcPc(3,3) = xformT1ToAcPc(3,3) / dt6.mmPerVox(3);
    roi.coords = mrAnatXformCoords(inv(xformT1ToAcPc), roi.coords);
    xLDOCC = floor(min(roi.coords(:,1)));
    xRDOCC = ceil(max(roi.coords(:,1)));

    fgDir = [subjDir '/conTrack/resamp_LDOCC'];
    disp(['cd ' fgDir]);
    cd(fgDir);
    for tt = threshVec
        strThresh = ['_thresh_' num2str(tt)];
        f = dir(fullfile(subjDir,'fibers','paths*STT_LDOCC*fd_image.nii.gz'));
        fgDensitySrcFile = fullfile(subjDir,'fibers',f.name);
        if bCompare2D
            mtrCompareDensities2D(subjDir, fgDensitySrcFile, ['*' strThresh], ['cc_2d_STT' strThresh '.mat'],'x',xLDOCC);
        else
            mtrCompareDensities(subjDir, fgDensitySrcFile, ['*_kSmooth_18*_kMidSD_0.175*' strThresh], [], ['cc_STT' strThresh '.mat']);
        end
    end   
    
    fgDir = [subjDir '/conTrack/resamp_RDOCC'];
    disp(['cd ' fgDir]);
    cd(fgDir);
    for tt = threshVec
        strThresh = ['_thresh_' num2str(tt)];
        f = dir(fullfile(subjDir,'fibers','paths*STT_RDOCC*fd_image.nii.gz'));
        fgDensitySrcFile = fullfile(subjDir,'fibers',f.name);
        if bCompare2D
            mtrCompareDensities2D(subjDir, fgDensitySrcFile, ['*' strThresh], ['cc_2d_STT' strThresh '.mat'],'x',xRDOCC);
        else
            mtrCompareDensities(subjDir, fgDensitySrcFile, ['*_kSmooth_18*_kMidSD_0.175*' strThresh], [], ['cc_STT' strThresh '.mat']);
        end
    end
end
