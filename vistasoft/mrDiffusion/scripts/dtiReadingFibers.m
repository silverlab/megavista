subDir = '/teal/scr1/dti/childSpmNorm_SIRL55msWarp1_trilin/subjectData/';
f = findSubjects(subDir, '_dt6', {'tk040817'});

faThresh = 0.25;

opts.stepSizeMm = 1;
opts.faThresh = 0.15;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.25 0.75];

groupDir = '/snarp/u1/data/reading_longitude/dti/groupAnalysis';

% Klingberg:
% "The VOI had a volume of 960 mm^3, and was located within x = -36 to -26, 
% y = -50 to -10, and z = 0 to 32 mm relative the to anterior commissure."
% (These are presumably MNI coordinates; peak at [-28 -20 28])
kCoordsMni = [-31 -20 26];
dCoordsMni = round(tal2mni([-28 -26 23]));
r(1) = dtiNewRoi('k05'); r(1).coords = dtiBuildSphereCoords(kCoordsMni, 5);
%r(2) = dtiNewRoi('d05'); r(2).coords = dtiBuildSphereCoords(dCoordsMni, 5);
for(ii=1:length(f))
    fname = f{ii};
    [junk,bn] = fileparts(fname);
    us = strfind(bn,'_'); bn = bn(1:us(1)-1);
    disp(['Processing ' num2str(ii) ': ' bn '...']);
    roiPath = fullfile(fileparts(fname), 'ROIs');
    fiberPath = fullfile(fileparts(fname), 'fibers');
    cc = load(fullfile(roiPath,'CC_FA'));

    if(exist(fullfile(fiberPath, 'LAllFG+k05.mat'), 'file'))
        disp('skipping.');
    else
        dt = load(fname);
        if(exist(fullfile(fiberPath, 'LAllFG.mat'), 'file'))
            load(fullfile(fiberPath, 'LAllFG.mat'));
        else
            dt.dt6(isnan(dt.dt6)) = 0;
            dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
            [eigVec, eigVal] = dtiSplitTensor(dt.dt6);
            clear eigVec;
            fa = dtiComputeFA(eigVal);
            clear eigVal;
    
            roiOcc = dtiNewRoi('all');
            mask = fa>=faThresh;
            [x,y,z] = ind2sub(size(mask), find(mask));
            roiOcc.coords = mrAnatXformCoords(dt.xformToAcPc, [x,y,z]);
    
            % LEFT ROI
            roi = dtiRoiClip(roiOcc, [0 80]);
            roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
            roi.name = 'LAll';
            %dtiWriteRoi(roi, fullfile(roiPath, roi.name), 1, 'acpc');
    
            % LEFT FIBERS
            fg = dtiFiberTrack(dt.dt6, roi.coords, dt.mmPerVox, dt.xformToAcPc, 'LAllFG',opts);
            dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
            %dtiWriteFiberGroup(fg, fullfile(fiberPath, [fg.name '_MNI']), 1, 'MNI', def);
            clear fg; clear mex;
        end
        
        % We need to invert the spatial normalization
        def = dt.t1NormParams;
        [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
        def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
        
        % WARP MNI ROIS TO THIS BRAIN & INTERSECT
        for(ii=1:length(r))
            roi = r(ii);
            roi.coords = mrAnatXformCoords(dt.t1NormParams.sn, roi.coords);
            roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
            dtiWriteRoi(roi, fullfile(roiPath, roi.name), 1, 'acpc');
            newFg = dtiIntersectFibersWithRoi(0, {'and'}, 1, roi, fg, inv(dt.xformToAcPc));
            newFg = dtiCleanFibers(newFg);
            dtiWriteFiberGroup(newFg, fullfile(fiberPath, newFg.name), 1, 'acpc', []);
            dtiWriteFiberGroup(newFg, fullfile(groupDir, [bn '_' newFg.name '_MNI']), 1, 'MNI', def);
            newFg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc.roi, newFg, inv(dt.xformToAcPc));
            dtiWriteFiberGroup(newFg, fullfile(fiberPath, newFg.name), 1, 'acpc', []);
            dtiWriteFiberGroup(newFg, fullfile(groupDir, [bn '_' newFg.name '_MNI']), 1, 'MNI', def);
        end
    end
end

