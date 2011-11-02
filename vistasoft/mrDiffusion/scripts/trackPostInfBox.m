baseDir = '/michal/DTI/ChildSpmNormTrilin20050425'; %running on Teal
% baseDir = '\\snarp\u1\data\reading_longitude\dti_adults';% on cyan
d = {'ave10','ave7', 'ave9','ave9-10', 'aveFemale', ...
        'aveMale', 'AvePhonAwareLow', 'AvePhonAwareMedHigh','ave11-12','ave7-8'};
f = {'averageDtAge10N17.mat', 'averageDtAge7N11.mat', 'averageDtAge9N11.mat','averageDtAge9-10N28.mat',...
        'averageDtFemalesN30.mat', 'averageDtMalesN24.mat', 'averageDtPhonAwareLowN20.mat',...
        'averageDtPhonAwareMedHighN34.mat', 'averageDtAge11-12N10.mat', 'averageDtAge7-8N16.mat'};
faThresh = 0.1;
leftClip = [-80 0]; %for clipping out the right hemi
rightClip = [0 80];
frontClip = [-20 80];
infClip = [-50 -30];
supClip = [50 80];
opts.stepSizeMm = 1;
opts.faThresh = 0.1;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.25 0.75];


for(ii=1:length(f))
    fname = fullfile(baseDir, d{ii}, f{ii});
    disp(['Processing ' fname '...']);
    roiPath = fullfile(fileparts(fname), 'ROIs');
    fiberPath = fullfile(fileparts(fname), 'fibers');
    dt = load(fname);
    dt.dt6(isnan(dt.dt6)) = 0;
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    [eigVec, eigVal] = dtiSplitTensor(dt.dt6);
    clear eigVec;
    fa = dtiComputeFA(eigVal);
    clear eigVal;
    
    %create a white matter mask
    roi = dtiNewRoi('wm');
    mask = fa>=faThresh;
    [x,y,z] = ind2sub(size(mask), find(mask));
    roi.coords = mrAnatXformCoords(dt.xformToAcPc, [x,y,z]);
    roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
    wm = roi;
 
    LroiName = 'LpostInfBox';
    Lroi = dtiNewRoi(LroiName);

    Lkeep = ones(size(wm.coords,1),1);
    Lkeep = Lkeep & (wm.coords(:,1)<rightClip(1) | wm.coords(:,1)>rightClip(2));%keep left
    Lkeep = Lkeep & (wm.coords(:,1)<infClip(1) | wm.coords(:,1)>infClip(2));%keep sup
    Lkeep = Lkeep & (wm.coords(:,1)<supClip(1) | wm.coords(:,1)>supClip(2));%keep inf-sup range
    Lkeep = Lkeep & (wm.coords(:,1)<frontClip(1) | wm.coords(:,1)>frontClip(2));%keep post
    Lcoords = wm.coords;
    Lroi.coords = Lcoords(Lkeep,:);
    
    RroiName = 'RpostInfBox';
    Rroi = dtiNewRoi(RroiName);

    Rkeep = ones(size(wm.coords,1),1);
    Rkeep = Rkeep & (wm.coords(:,1)<leftClip(1) | wm.coords(:,1)>leftClip(2));%keep right
    Rkeep = Rkeep & (wm.coords(:,1)<infClip(1) | wm.coords(:,1)>infClip(2));%keep sup
    Rkeep = Rkeep & (wm.coords(:,1)<supClip(1) | wm.coords(:,1)>supClip(2));%keep inf-sup range
    Rkeep = Rkeep & (wm.coords(:,1)<frontClip(1) | wm.coords(:,1)>frontClip(2));%keep post
    Rcoords = wm.coords;
    Rroi.coords = Rcoords(Rkeep,:);
 
    dtiWriteRoi(Lroi, fullfile(roiPath, LroiName));
    dtiWriteRoi(Rroi, fullfile(roiPath, RroiName));

    Lfg = dtiFiberTrack(dt.dt6, Lroi.coords, dt.mmPerVox, dt.xformToAcPc, 'LpostInfBox',opts);
    Rfg = dtiFiberTrack(dt.dt6, Rroi.coords, dt.mmPerVox, dt.xformToAcPc, 'LpostInfBox',opts);
    dtiWriteFiberGroup(Lfg, fullfile(fiberPath, Lfg.name), 1, 'acpc');
    dtiWriteFiberGroup(Rfg, fullfile(fiberPath, Rfg.name), 1, 'acpc');
end

