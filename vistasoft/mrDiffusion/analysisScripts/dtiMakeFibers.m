% [f,sc] = findSubjects([],[],{'ab040913' 'ad040522' 'ada041018' 'ajs040629' 'am040925' 'an041018',... 
% 'ao041022' 'ar040522' 'at040918' 'bg040719' 'ch040712' 'clr040629' 'cp041009',... 
% 'crb040707' 'ctb040706' 'ctr040618' 'da040701' 'dh040607' 'dm040922' 'es041113',... 
% 'hy040602' 'jh040522' 'js040726' 'jt040717' 'kj040929' 'ks040720' 'lg041019',... 
% 'lj040527' 'll040607' 'mb041004' 'md040714' 'mh040630' 'mho040625' 'mm040925',... 
% 'mn041014' 'nad040610' 'nf040812' 'nid040610' 'pf040608' 'pt041013' 'rd041005',... 
% 'rh040630' 'rs040918' 'rsh041103' 'sg040910' 'sl040609' 'ss040804' 'sy040706',... 
% 'tk040817'});

% if(ispc)
%     baseDir = '//171.64.204.10/biac2-wandell2/data/reading_longitude/dti_Adults/*0*';
% else
%     baseDir = '//biac2/wandell2/data/reading_longitude/dti_Adults/*0*';
% end

% For Template
if(ispc)
    baseDir = '//171.64.204.10/biac3-wandell4/data/reading_longitude/dti_y1/*0*';
else
    baseDir = '//biac3/wandell4/data/reading_longitude/dti_y1/*0*';
end
[f,sc] = findSubjects(baseDir, '*_dt6');
% [f,sc] = findSubjects(baseDir, '*_dt6', {'ab050307','ah050902', 'ah051003', 'ams051015', 'as050307', 'aw040809',...
%                       'bw040922','bw040806','da050311','gd040521','gd040901','gf051007', 'gf050826','gm050308',...
%                       'jl040806','jl040902','ka040923','kt040517','mbs040503','mbs040908','me050126',...
%                       'mz040604','mz040828','pp050511','pp050208','rd040901', 'rd040630',...
%                       'rd050504','rk050524','sd050527','sn040831','sp050303','sr040513',...
%                       'tl051015','rd050208'});


faThresh = 0.25;

opts.stepSizeMm = 1;
opts.faThresh = 0.15;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.5];

for(ii=3:length(f))
    fname = f{ii};
    disp(['Processing ' fname '...']);
    roiPath = fullfile(fileparts(fname), 'ROIs');
    fiberPath = fullfile(fileparts(fname), 'fibers');
    
    cc = load(fullfile(roiPath,'CC'));
    dt = load(fname);
    dt.dt6(isnan(dt.dt6)) = 0;
    % Apply the brain mask, if it exists (older dt6 files are pre-masked)
    if(isfield(dt,'brainMask'))
      dt.dt6(repmat(~dt.brainMask, [1,1,1,6])) = 0;
    end
%    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    fa = dtiComputeFA(dt.dt6);
    
    roiAll = dtiNewRoi('all');
    mask = fa>=faThresh;
    [x,y,z] = ind2sub(size(mask), find(mask));
    roiAll.coords = mrAnatXformCoords(dt.xformToAcPc, [x,y,z]);
    
    % LEFT ROI
    roi = dtiRoiClip(roiAll, [0 80]);
    roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
    roi.name = 'left';
    dtiWriteRoi(roi, fullfile(roiPath, roi.name));
    
    % LEFT FIBERS
    fg = dtiFiberTrack(dt.dt6, roi.coords, dt.mmPerVox, dt.xformToAcPc, 'LFG',opts);
    fg = dtiCleanFibers(fg);
    dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
	fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc.roi, fg);
    dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
    
    % RIGHT ROI
    roi = dtiRoiClip(roiAll, [-80 0]);
    roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
    roi.name = 'right';
    dtiWriteRoi(roi, fullfile(roiPath, roi.name));
    
    % RIGHT FIBERS
    fg = dtiFiberTrack(dt.dt6, roi.coords, dt.mmPerVox, dt.xformToAcPc, 'RFG',opts);
    fg = dtiCleanFibers(fg);
    dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
	fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc.roi, fg);
	dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
end
