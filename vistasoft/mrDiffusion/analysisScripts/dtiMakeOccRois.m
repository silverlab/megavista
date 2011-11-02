f = findSubjects;

% 
% COMPUTE OCC FIBERS
%
faThresh = 0.25;
opts.stepSizeMm = 1;
opts.faThresh = 0.15;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.25 0.75];
for(ii=1:length(f))
    fname = f{ii};
    disp(['Processing ' fname '...']);
    roiPath = fullfile(fileparts(fname), 'ROIs');
    fiberPath = fullfile(fileparts(fname), 'fibers');
    
    cc = load(fullfile(roiPath,'CC_FA'));
    dt = load(fname);
    dt.dt6(isnan(dt.dt6)) = 0;
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    [eigVec, eigVal] = dtiSplitTensor(dt.dt6);
    clear eigVec;
    fa = dtiComputeFA(eigVal);
    clear eigVal;
    
    roiOcc = dtiNewRoi('occ');
    mask = fa>=faThresh;
    [x,y,z] = ind2sub(size(mask), find(mask));
    roiOcc.coords = mrAnatXformCoords(dt.xformToAcPc, [x,y,z]);
    
    % We need to invert the spatial normalization
    %def = dt.t1NormParams;
    %[def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
    %def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
    
    % LEFT ROI
    posteriorEdgeOfCC = min(cc.roi.coords(:,2));
    roi = dtiRoiClip(roiOcc, [0 80], [posteriorEdgeOfCC 80]);
    roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
    roi.name = 'LOcc';
    save(fullfile(roiPath, roi.name), 'roi');
    
    % LEFT FIBERS
    fg = dtiFiberTrack(dt.dt6, roi.coords, dt.mmPerVox, dt.xformToAcPc, 'LOccFG',opts);
    fg = dtiCleanFibers(fg);
    dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
    fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc.roi, fg, inv(dt.xformToAcPc));
    dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
    %dtiWriteFiberGroup(fg, fullfile(fiberPath, [fg.name '_MNI']), 1, 'MNI', def);
    
    % RIGHT ROI
    roi = dtiRoiClip(roiOcc, [-80 0], [posteriorEdgeOfCC 80]);
    roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
    roi.name = 'ROcc';
    save(fullfile(roiPath, roi.name), 'roi');
    
    % RIGHT FIBERS
    fg = dtiFiberTrack(dt.dt6, roi.coords, dt.mmPerVox, dt.xformToAcPc, 'ROccFG',opts);
    fg = dtiCleanFibers(fg);
    dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
    fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc.roi, fg, inv(dt.xformToAcPc));
    dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
    %dtiWriteFiberGroup(fg, fullfile(fiberPath, [fg.name '_MNI']), 1, 'MNI', def);
end

%
% NORMALIZE FIBERS
%
% f = findSubjects;
% for(ii=1:length(f))
%     fname = f{ii};
%     disp(['Processing ' fname '...']);
%     fiberPath = fullfile(fileparts(fname), 'fibers');
%     dt = load(fname, 't1NormParams');
%     def = dt.t1NormParams;
%     [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
%     def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
%     fgStruct = load(fullfile(fiberPath,'LOccFG+CC_FA'));
%     dtiWriteFiberGroup(fgStruct.fg, fullfile(fiberPath, [fgStruct.fg.name '_MNI']), 1, 'MNI', def);
%     fgStruct = load(fullfile(fiberPath,'ROccFG+CC_FA'));
%     dtiWriteFiberGroup(fgStruct.fg, fullfile(fiberPath, [fgStruct.fg.name '_MNI']), 1, 'MNI', def);
% end

%
% INTERSECT FIBERS
%
% Warp normalized ROIs to each subject's brain and intersect the FGs.
%
roiDir = '/snarp/u1/data/reading_longitude/dtiGroupAnalysis/sgOcc_SIRL55_ROIs/';
%d = dir(fullfile(roiDir,'*.mat'));
l(1) = load(fullfile(roiDir, 'LV3AB7'));
l(2) = load(fullfile(roiDir, 'LV12d'));
l(3) = load(fullfile(roiDir, 'LV12v'));
l(4) = load(fullfile(roiDir, 'LV3hV4'));
r(1) = load(fullfile(roiDir, 'RV3AB7'));
r(2) = load(fullfile(roiDir, 'RV12d'));
r(3) = load(fullfile(roiDir, 'RV12v'));
r(4) = load(fullfile(roiDir, 'RV3hV4'));
for(ii=1:4)
    l(ii).roi.coords = l(ii).roi.coords(~any(isnan(l(ii).roi.coords')),:);
    l(ii).roi = dtiRoiClean(l(ii).roi, 3, {'fillHoles','removeSat','dilate'});
    l(ii).roi.name = ['sg_' l(ii).roi.name];
    r(ii).roi.coords = r(ii).roi.coords(~any(isnan(r(ii).roi.coords')),:);
    r(ii).roi = dtiRoiClean(r(ii).roi, 3, {'fillHoles','removeSat','dilate'});
    r(ii).roi.name = ['sg_' r(ii).roi.name];
end

colors = [20 200 20; 20 200 200; 200 20 200; 200 20 20];
tdir = 'e:\data\templates\';
templateName = 'SIRL55ms_warp2_brain.img';
spm_defaults;
params = defaults.normalise.estimate;
params.smosrc = 4;
template = fullfile(tdir, templateName);
for(ii=1:length(f))
    fname = f{ii};
    disp(['Processing ' fname '...']);
    dt = load(fname);
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;

    disp(['Computing new sn for ' fname '...']);
    img = mrAnatHistogramClip(double(dt.anat.img),0.4,0.985);
    xform = dt.anat.xformToAcPc;
    img(~dt.anat.brainMask) = 0;
    t1NormParams.sn = mrAnatComputeSpmSpatialNorm(img, xform, template, params);
    dt.t1NormParams = t1NormParams;
    % We need to invert the spatial normalization
    def = dt.t1NormParams;
    [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
    def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
%*** WORK HERE ***

    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath = fullfile(fileparts(fname), 'ROIs');
    cc = load(fullfile(roiPath, 'CC_FA')); cc = cc.roi;
    % We'll clip any fibers that penetrate a plane that is 25% the length
    % of the CC, starting from the posterior edge.
    apClip = (max(cc.coords(:,2))-min(cc.coords(:,2)))*.25+min(cc.coords(:,2));
    fgL = load(fullfile(fiberPath,'LOccFG+CC_FA'));
    fgR = load(fullfile(fiberPath,'ROccFG+CC_FA'));
    for(jj=1:4)
        roi = l(jj).roi;
        roi.coords = mrAnatXformCoords(dt.t1NormParams.sn, roi.coords);
        dtiWriteRoi(roi, fullfile(roiPath, roi.name), l(jj).versionNum, 'acpc');
        fg = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, 3, roi, fgL.fg, inv(dt.xformToAcPc));
        fg = dtiCleanFibers(fg, [NaN apClip NaN]);
        fg.colorRgb = colors(jj,:);
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc');
        roi = r(jj).roi;
        roi.coords = mrAnatXformCoords(dt.t1NormParams.sn, roi.coords);
        dtiWriteRoi(roi, fullfile(roiPath, roi.name), r(jj).versionNum, 'acpc');
        fg = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, 3, roi, fgR.fg, inv(dt.xformToAcPc));
        fg = dtiCleanFibers(fg, [NaN apClip NaN]);
        fg.colorRgb = colors(jj,:);
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc');
    end
end

%
% SAVE SLICE IMAGES
%
f = findSubjects;
outDir = '/silver/scr1/dti';
upSamp = 4;
acpcPos = [0 -50 10];
for(ii=1:length(f))
    [junk,bn] = fileparts(f{ii});
    us = strfind(bn,'_'); bn = bn(1:us(1)-1);
    disp(['Processing ' num2str(ii) ': ' bn '...']);
    fiberPath = fullfile(fileparts(f{ii}), 'fibers');
    dt = load(f{ii}, 'xformToAnat', 'anat');
    bg = dt.anat;
    bg.img = mrAnatHistogramClip(double(bg.img), 0.3, 0.98);
    bg.acpcToImgXform = inv(bg.xformToAcPc);

    load(fullfile(fiberPath, 'LOccFG+CC_FA+LV3AB')); fgs(1) = fg;
    load(fullfile(fiberPath, 'LOccFG+CC_FA+LV12d')); fgs(2) = fg;
    load(fullfile(fiberPath, 'LOccFG+CC_FA+LV12v')); fgs(3) = fg;
    load(fullfile(fiberPath, 'LOccFG+CC_FA+LV34')); fgs(4) = fg;
    load(fullfile(fiberPath, 'ROccFG+CC_FA+RV3AB')); fgs(5) = fg;
    load(fullfile(fiberPath, 'ROccFG+CC_FA+RV12d')); fgs(6) = fg;
    load(fullfile(fiberPath, 'ROccFG+CC_FA+RV12v')); fgs(7) = fg;
    load(fullfile(fiberPath, 'ROccFG+CC_FA+RV34')); fgs(8) = fg;
    [fgs(1:8).visible] = deal(1);
    fname = fullfile(outDir, [bn '_LRocc']);
    dtiSaveImageSlicesOverlays(0, fgs, [], 0, fname, upSamp, acpcPos, bg);
    [fgs(5:8).visible] = deal(0);
    fname = fullfile(outDir, [bn '_Locc']);
    dtiSaveImageSlicesOverlays(0, fgs, [], 0, fname, upSamp, acpcPos, bg);
    [fgs(1:4).visible] = deal(0); [fgs(5:8).visible] = deal(1);
    fname = fullfile(outDir, [bn '_Rocc']);
    dtiSaveImageSlicesOverlays(0, fgs, [], 0, fname, upSamp, acpcPos, bg);
end

f = findSubjects([],[],{'mb040927'});
outDir = '/silver/scr1/dti';
upSamp = 1;
acpcPos = [0 -50 10];
for(ii=54:length(f))
    [junk,bn] = fileparts(f{ii});
    us = strfind(bn,'_'); bn = bn(1:us(1)-1);
    disp(['Processing ' num2str(ii) ': ' bn '...']);
    fiberPath = fullfile(fileparts(f{ii}), 'fibers');
    dt = load(f{ii}, 'xformToAnat', 'anat');
    bg = dt.anat;
    bg.img = mrAnatHistogramClip(double(bg.img), 0.3, 0.98);
    bg.acpcToImgXform = inv(bg.xformToAcPc);

    %fname = fullfile(outDir, [bn '_LRocc']);
    fname = '';
    imX = dtiSaveImageSlicesOverlays(0, [], [], 0, fname, upSamp, acpcPos, bg);
    im(:,:,ii) = imX(:,:,1);
end

