% this script tracks whole brain and intersects with an unthresholded
% BA44+45 ROI resulting in a managable fiber group.
% next steps:   1.clip BA44+45 to L/R ROIs and intersect separately with each,
%                   to yield two fgs.       DONE, needs debug
%               2. add the next steps of analysis:  
%                   a. create mutually exclusive ROIs for each BA in each hemi, for thresholds
%                       0.3-0.4-0.5-0.6-0.7-0.8
%                   b. split by endpoints with these rois.

baseDir = '//snarp/u1/data/reading_longitude/dti_adults'; %on Teal
% baseDir = '\\snarp\u1\data\reading_longitude\dti_adults';% on cyan
f = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
        'jl040902','ka040923','mbs040503', 'me050126', 'mz040828',...
        'pp050208', 'rd040630','sn040831','sp050303'};

 
% f = {'mbs040503'}; %for debug

% parameter setting for tracking
 
faThresh = 0.25;%for average brain: faThresh = 0.15;
pValues = [0.05 0.25 0.35 0.45 0.55 0.65 0.75 inf];% .7 is lowest value that will still yield non empty ROIs in all hemis and BAs
colors = 'wbcgmry'; %ROI colors - discrete
rgb = [20,90,200;0,200,200;160,200,90;20,200,20;200,200,0;200,100,0;200,0,0]; % fg colors:  blue(0.05) to red(0.7)
rlClip = [0 80]; %for clipping out the right hemi
opts.stepSizeMm = 1;
opts.faThresh = 0.15; % maybe should be even .1 for average brain
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.25 0.75];
%location of normalized maps
cytoarchDir = fullfile(fileparts(which('spm_normalise')), 'templates', 'cytoarch');
ba44MapFile = fullfile(cytoarchDir, 'BrocaN10_44_b_nlin2StdMNI.mnc');
ba45MapFile = fullfile(cytoarchDir, 'BrocaN10_45_b_nlin2StdMNI.mnc');
%
for(ii=1:length(f))
    fname = fullfile(baseDir, f{ii}, [f{ii} '_dt6.mat']);
    disp(['Processing ' fname '...']);
    roiPath = fullfile(fileparts(fname), 'ROIs','BA44-45');
    fiberPath = fullfile(fileparts(fname), 'fibers','BA44-45');
    mkdir(fullfile(fileparts(fname), 'ROIs'),'BA44-45'); 
    mkdir(fullfile(fileparts(fname), 'fibers'),'BA44-45'); 
    dt = load(fname);
    dt.dt6(isnan(dt.dt6)) = 0;
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    fa = dtiComputeFA(dt.dt6);
    
    %create a white matter mask
    roi = dtiNewRoi('wm');
    mask = fa>=faThresh;
    [x,y,z] = ind2sub(size(mask), find(mask));
    roi.coords = mrAnatXformCoords(dt.xformToAcPc, [x,y,z]);
    roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
    save(fullfile(roiPath, roi.name), 'roi');
    wm = roi;
    
    % Import the Amunts maps
    % We need to invert the spatial normalization
    %def = dt.t1NormParams;
    spmDir = fileparts(which('spm_normalise'));
    template = fullfile(spmDir, 'templates', 'T1.mnc');
    spm_defaults;
    params = defaults.normalise.estimate;
    img = mrAnatHistogramClip(double(dt.anat.img), 0.4, 0.985);
    t1NormParams.sn = mrAnatComputeSpmSpatialNorm(img, dt.anat.xformToAcPc, template, params);
    disp('Appending new normalization to original dt6 file...');
    save(fname, 't1NormParams', '-APPEND');
    def = t1NormParams;

    [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
    def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
    
    % Use the T1 bounding box
    bb = dt.anat.xformToAcPc*[1,1,1,1;[size(dt.anat.img),1]]';
    bb = bb(1:3,:)';
    [ba44, mmPerVox] = dtiWarpMapToSubject(def, bb, ba44MapFile);
    [ba45, mmPerVox] = dtiWarpMapToSubject(def, bb, ba45MapFile);
    fa = mrAnatResliceSpm(fa, inv(dt.xformToAcPc), bb, mmPerVox, [1 1 1 0 0 0]);
    
    %create ME ROIs .05:.3, .3:.4, etc, and clip L/R
    % for BA44 - BOB: why are these smaller than the GUI created ones? and why
    % do we need the 10 factor here and not in dtiFiberUI?
    % ME ROIs for BA44                  check why the last roi is empty
    for(jj = 2:length(pValues))
        LroiName = ['LBA44_ME_' num2str(round(pValues(jj-1)*100),'%03d')];
        RroiName = ['RBA44_ME_' num2str(round(pValues(jj-1)*100),'%03d')];
        Lroi = dtiNewRoi(LroiName, colors(mod(jj-2,length(colors))+1));
        Rroi = dtiNewRoi(RroiName, colors(mod(jj-2,length(colors))+1));
        mask = (ba44>=10*pValues(jj-1) & ba44<10*pValues(jj));
        [x,y,z] = ind2sub(size(mask), find(mask));
        roi.coords = mrAnatXformCoords(dt.anat.xformToAcPc, [x,y,z]);
        keep = ones(size(roi.coords,1),1);
        if(~isempty(rlClip))
            keep = keep & (roi.coords(:,1)<rlClip(1) | roi.coords(:,1)>rlClip(2));
        end
        coords = roi.coords;
        Lroi.coords = coords(keep,:);
        Rroi.coords = coords(~keep,:);
        dtiWriteRoi(Lroi, fullfile(roiPath, LroiName));
        dtiWriteRoi(Rroi, fullfile(roiPath, RroiName));
        %save(fullfile(roiPath, roi.name), 'roi');
        LBA44_ME(jj-1) = Lroi;%   
        RBA44_ME(jj-1) = Rroi;%  
    end
        
    % ME ROIs for BA45
    for(jj = 2:length(pValues))
        LroiName = ['LBA45_ME_' num2str(round(pValues(jj-1)*100),'%03d')];
        RroiName = ['RBA45_ME_' num2str(round(pValues(jj-1)*100),'%03d')];
        Lroi = dtiNewRoi(LroiName, colors(mod(jj-2,length(colors))+1));
        Rroi = dtiNewRoi(RroiName, colors(mod(jj-2,length(colors))+1));
        mask = (ba45>=10*pValues(jj-1) & ba45<10*pValues(jj));
        [x,y,z] = ind2sub(size(mask), find(mask));
        roi.coords = mrAnatXformCoords(dt.anat.xformToAcPc, [x,y,z]);
        keep = ones(size(roi.coords,1),1);
        if(~isempty(rlClip))
            keep = keep & (roi.coords(:,1)<rlClip(1) | roi.coords(:,1)>rlClip(2));
        end
        coords = roi.coords;
        Lroi.coords = coords(keep,:);
        Rroi.coords = coords(~keep,:);
        dtiWriteRoi(Lroi, fullfile(roiPath, LroiName));
        dtiWriteRoi(Rroi, fullfile(roiPath, RroiName));
        %save(fullfile(roiPath, roi.name), 'roi');
        LBA45_ME(jj-1) = Lroi;% curly brackets??   
        RBA45_ME(jj-1) = Rroi;% curly brackets??   
    end
        
    %create full ROIs for each pValue
    % for L/R BA44
    for(jj = 1:(length(pValues)-1))
        LroiName = ['LBA44_full_' num2str(round(pValues(jj)*100),'%03d')];
        RroiName = ['RBA44_full_' num2str(round(pValues(jj)*100),'%03d')];
        Lroi = dtiNewRoi(LroiName, colors(mod(jj-1,length(colors))+1));
        Rroi = dtiNewRoi(RroiName, colors(mod(jj-1,length(colors))+1));
        mask = ba44>=10*pValues(jj) & ba44<inf;
        [x,y,z] = ind2sub(size(mask), find(mask));
        roi.coords = mrAnatXformCoords(dt.anat.xformToAcPc, [x,y,z]);
        keep = ones(size(roi.coords,1),1);
        if(~isempty(rlClip))
            keep = keep & (roi.coords(:,1)<rlClip(1) | roi.coords(:,1)>rlClip(2));
        end
        coords = roi.coords;
        Lroi.coords = coords(keep,:);
        Rroi.coords = coords(~keep,:);
        dtiWriteRoi(Lroi, fullfile(roiPath, LroiName));
        dtiWriteRoi(Rroi, fullfile(roiPath, RroiName));
        LBA44_full(jj) = Lroi;% 
        RBA44_full(jj) = Rroi;%  
    end
      
    %create full ROIs for L/R BA45
    for(jj = 1:(length(pValues)-1))
        LroiName = ['LBA45_full_' num2str(round(pValues(jj)*100),'%03d')];
        RroiName = ['RBA45_full_' num2str(round(pValues(jj)*100),'%03d')];
        Lroi = dtiNewRoi(LroiName, colors(mod(jj-1,length(colors))+1));
        Rroi = dtiNewRoi(RroiName, colors(mod(jj-1,length(colors))+1));
        mask = ba45>=10*pValues(jj);
        [x,y,z] = ind2sub(size(mask), find(mask));
        roi.coords = mrAnatXformCoords(dt.anat.xformToAcPc, [x,y,z]);
        keep = ones(size(roi.coords,1),1);
        if(~isempty(rlClip))
            keep = keep & (roi.coords(:,1)<rlClip(1) | roi.coords(:,1)>rlClip(2));
        end
        coords = roi.coords;
        Lroi.coords = coords(keep,:);
        Rroi.coords = coords(~keep,:);
        dtiWriteRoi(Lroi, fullfile(roiPath, LroiName));
        dtiWriteRoi(Rroi, fullfile(roiPath, RroiName));
        %save(fullfile(roiPath, roi.name), 'roi');
        LBA45_full(jj) = Lroi; % curly brackets??       
        RBA45_full(jj) = Rroi; % curly brackets??   
    end
    
      
    %create LBA44+45_005, RBA44+45_005 masks
    LroiName = 'LBA44+45_all';
    RroiName = 'RBA44+45_all';
    Lroi = dtiNewRoi(LroiName);
    Rroi = dtiNewRoi(RroiName);
    mask = (ba44>=10*pValues(1) | ba45>=10*pValues(1));
    [x,y,z] = ind2sub(size(mask), find(mask));
    roi.coords = mrAnatXformCoords(dt.anat.xformToAcPc, [x,y,z]);
    keep = ones(size(roi.coords,1),1);
    if(~isempty(rlClip))
        keep = keep & (roi.coords(:,1)<rlClip(1) | roi.coords(:,1)>rlClip(2));
    end
    coords = roi.coords;
    Lroi.coords = coords(keep,:);
    Rroi.coords = coords(~keep,:);
    dtiWriteRoi(Lroi, fullfile(roiPath, LroiName));
    dtiWriteRoi(Rroi, fullfile(roiPath, RroiName));
    Lba44_ba45 = Lroi;
    Rba44_ba45 = Rroi;
        
    % Track the whole brain
    fg = dtiFiberTrack(dt.dt6, wm.coords, dt.mmPerVox, dt.xformToAcPc, 'wholeBrain',opts);
    dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []); %save whole brain - do this only in special cases
    
    % Intersect with the Lba44+ba45, Rba44+ba45 ROIs to get two managable fiber groups.
    fgLeft = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, .87, Lba44_ba45, fg, inv(dt.xformToAcPc)); 
    fgRight = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, .87, Rba44_ba45, fg, inv(dt.xformToAcPc));
    dtiWriteFiberGroup(fgLeft, fullfile(fiberPath, fgLeft.name), 1, 'acpc');
    dtiWriteFiberGroup(fgRight, fullfile(fiberPath, fgRight.name), 1, 'acpc');
        
%     %save fgLeft fgRight in MNI space too     not now, space considerations
%     def = dt.t1NormParams;
%     [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
%     def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
%     dtiWriteFiberGroup(fgLeft, fullfile(fiberPath, [fgLeft.name '_MNI']), 1, 'MNI', def);
%     dtiWriteFiberGroup(fgRight, fullfile(fiberPath, [fgRight.name '_MNI']), 1, 'MNI', def);
    clear fg;
    
    
%     %for debug
%     fgLeft = load(fullfile(fiberPath,'wholeBrain+LBA44+45_all.mat'));
%     fgRight = load(fullfile(fiberPath,'wholeBrain+RBA44+45_all.mat'));
%     fgLeft = fgLeft.fg;
%     fgRight = fgRight.fg;
    
    
    %SPLIT each fiber group by endpoints with multiple ROIs 
    [LBA44fgSplit,contentious] = dtiIntersectFibersWithRoi(0, {'div','endpoints'},.87, LBA44_ME, fgLeft, inv(dt.xformToAcPc));
    [LBA45fgSplit,contentious] = dtiIntersectFibersWithRoi(0, {'div','endpoints'},.87, LBA45_ME, fgLeft, inv(dt.xformToAcPc));
    [RBA44fgSplit,contentious] = dtiIntersectFibersWithRoi(0, {'div','endpoints'},.87, RBA44_ME, fgRight, inv(dt.xformToAcPc));
    [RBA45fgSplit,contentious] = dtiIntersectFibersWithRoi(0, {'div','endpoints'},.87, RBA45_ME, fgRight, inv(dt.xformToAcPc));
    
    %last cell is the remaining - don't need to save those.
    LBA44fgSplit = LBA44fgSplit(1:length(LBA44fgSplit)-1);
    LBA45fgSplit = LBA45fgSplit(1:length(LBA45fgSplit)-1);
    RBA44fgSplit = RBA44fgSplit(1:length(RBA44fgSplit)-1);
    RBA45fgSplit = RBA45fgSplit(1:length(RBA45fgSplit)-1);
    
    
    % and (endpoints) each fg with full ROIs 
    for jj=1:length(LBA44_full)
        LBA44fgFull(jj) = dtiIntersectFibersWithRoi(0, {'and','endpoints'},.87, LBA44_full(jj), fgLeft, inv(dt.xformToAcPc));
        LBA45fgFull(jj) = dtiIntersectFibersWithRoi(0, {'and','endpoints'},.87, LBA45_full(jj), fgLeft, inv(dt.xformToAcPc));
        RBA44fgFull(jj) = dtiIntersectFibersWithRoi(0, {'and','endpoints'},.87, RBA44_full(jj), fgRight, inv(dt.xformToAcPc));
        RBA45fgFull(jj) = dtiIntersectFibersWithRoi(0, {'and','endpoints'},.87, RBA45_full(jj), fgRight, inv(dt.xformToAcPc));
    end

    %saving split fgs in ac-pc          (MNI disabled for now, space cons.)
    for jj=1:length(LBA44fgSplit)
        LBA44fgSplit(jj).colorRgb = rgb(jj,:);
        LBA45fgSplit(jj).colorRgb = rgb(jj,:);
        RBA44fgSplit(jj).colorRgb = rgb(jj,:);
        RBA45fgSplit(jj).colorRgb = rgb(jj,:);
        
        dtiWriteFiberGroup(LBA44fgSplit(jj), fullfile(fiberPath, LBA44fgSplit(jj).name), 1, 'acpc');
        dtiWriteFiberGroup(LBA45fgSplit(jj), fullfile(fiberPath, LBA45fgSplit(jj).name), 1, 'acpc');
        dtiWriteFiberGroup(RBA44fgSplit(jj), fullfile(fiberPath, RBA44fgSplit(jj).name), 1, 'acpc');
        dtiWriteFiberGroup(RBA45fgSplit(jj), fullfile(fiberPath, RBA45fgSplit(jj).name), 1, 'acpc');
        
%         dtiWriteFiberGroup(LBA44fgSplit(jj), fullfile(fiberPath, [LBA44fgSplit(jj).name '_MNI']), 1, 'MNI', def);    
%         dtiWriteFiberGroup(LBA45fgSplit(jj), fullfile(fiberPath, [LBA45fgSplit(jj).name '_MNI']), 1, 'MNI', def);
%         dtiWriteFiberGroup(RBA44fgSplit(jj), fullfile(fiberPath, [RBA44fgSplit(jj).name '_MNI']), 1, 'MNI', def);
%         dtiWriteFiberGroup(RBA45fgSplit(jj), fullfile(fiberPath, [RBA45fgSplit(jj).name '_MNI']), 1, 'MNI', def);
    end

    %saving full fgs in ac-pc         (MNI disabled for now, space cons.)
    for jj=1:length(LBA44fgFull)
        LBA44fgFull(jj).colorRgb = rgb(jj,:);
        LBA45fgFull(jj).colorRgb = rgb(jj,:);
        RBA44fgFull(jj).colorRgb = rgb(jj,:);
        RBA45fgFull(jj).colorRgb = rgb(jj,:);
        
        dtiWriteFiberGroup(LBA44fgFull(jj), fullfile(fiberPath, LBA44fgFull(jj).name), 1, 'acpc');
        dtiWriteFiberGroup(LBA45fgFull(jj), fullfile(fiberPath, LBA45fgFull(jj).name), 1, 'acpc');
        dtiWriteFiberGroup(RBA44fgFull(jj), fullfile(fiberPath, RBA44fgFull(jj).name), 1, 'acpc');
        dtiWriteFiberGroup(RBA45fgFull(jj), fullfile(fiberPath, RBA45fgFull(jj).name), 1, 'acpc');
        
%         dtiWriteFiberGroup(LBA44fgFull(jj), fullfile(fiberPath, [LBA44fgFull(jj).name '_MNI']), 1, 'MNI', def);    
%         dtiWriteFiberGroup(LBA45fgFull(jj), fullfile(fiberPath, [LBA45fgFull(jj).name '_MNI']), 1, 'MNI', def);
%         dtiWriteFiberGroup(RBA44fgFull(jj), fullfile(fiberPath, [RBA44fgFull(jj).name '_MNI']), 1, 'MNI', def);
%         dtiWriteFiberGroup(RBA45fgFull(jj), fullfile(fiberPath, [RBA45fgFull(jj).name '_MNI']), 1, 'MNI', def);
    end
    
    % save full fgs for p50 and on in MNI only 
    for jj=4:length(LBA44fgFull)
        LBA44fgFull(jj).colorRgb = rgb(jj,:);
        LBA45fgFull(jj).colorRgb = rgb(jj,:);
        RBA44fgFull(jj).colorRgb = rgb(jj,:);
        RBA45fgFull(jj).colorRgb = rgb(jj,:);
        
%         dtiWriteFiberGroup(LBA44fgFull(jj), fullfile(fiberPath, LBA44fgFull(jj).name), 1, 'acpc');
%         dtiWriteFiberGroup(LBA45fgFull(jj), fullfile(fiberPath, LBA45fgFull(jj).name), 1, 'acpc');
%         dtiWriteFiberGroup(RBA44fgFull(jj), fullfile(fiberPath, RBA44fgFull(jj).name), 1, 'acpc');
%         dtiWriteFiberGroup(RBA45fgFull(jj), fullfile(fiberPath, RBA45fgFull(jj).name), 1, 'acpc');
        
        dtiWriteFiberGroup(LBA44fgFull(jj), fullfile(fiberPath, [LBA44fgFull(jj).name '_MNI']), 1, 'MNI', def);    
        dtiWriteFiberGroup(LBA45fgFull(jj), fullfile(fiberPath, [LBA45fgFull(jj).name '_MNI']), 1, 'MNI', def);
        dtiWriteFiberGroup(RBA44fgFull(jj), fullfile(fiberPath, [RBA44fgFull(jj).name '_MNI']), 1, 'MNI', def);
        dtiWriteFiberGroup(RBA45fgFull(jj), fullfile(fiberPath, [RBA45fgFull(jj).name '_MNI']), 1, 'MNI', def);
    end

    clear fg*;
end
