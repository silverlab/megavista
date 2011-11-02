% dtiTrackFibersMIND
% 
% This script takes a group of subjects in subCodeList and: 
% 1.  Tracks all fibers in each hemisphere. 
% 1a. If a CC.mat ROI is not in the ROIs directory, one will be
%     created. The user will be notified and the ROI should be examined.
% 2.  Clips each hemisphere's fibers so that only nPts (10 by default)
%     remain in the opposite hemisphere. 
% 3.  Merges the two fiber groups (optional) 
% 4.  Saves the fiber groups in .pdb format so that the fibers can be
%     loaded in Quench. 
% 
% *** You may want to save each hemisphere's fiber group seperately and
% merge them in the next step- where we could also extract the diffusion
% data. Right now you may have problems with Quench being slow or crashing
% with that many fibers loaded. *** This would recquire that each fiber
% group be saved for each hemisphere. They would then be merged and saved.
% This is troublesome but workable. You also have the option to save both.
% See line 32.
%
% HISTORY: 
% 09.24.2009 - LMP wrote the thing. 

%% Directory Structure

baseDir = '/home/christine/APP/stanford_DTI/';
subCodeList = '/home/christine/APP/stanford_DTI/APPlist.txt';
subs = textread(subCodeList, '%s'); fprintf('\nWill process %d subjects...\n\n',numel(subs));
dirs = 'dti30trilinrt'; % This is the subFolder that contains the dt6.mat file (eg. dti30trilinrt) 

% MERGE the fiber groups
merge = 2; % 0=do not merge fiber groups, 1=merge fiber groups, 2=save out both.
fileFormat = 1; % 0 for .m, 1 for .pdb

%% Tracking Parameters

faThresh = 0.35;
opts.stepSizeMm = 1;
opts.faThresh = 0.15;
opts.lengthThreshMm = [20 250];
opts.angleThresh = 60;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [-.25 .25]; % 8 fibers per voxel.
nPts = 10; % Number of points to keep on a given side of the midSagital plane.

%% Loops through subs and tracks fibers

for ii=1:numel(subs)
    subDir = fullfile(baseDir,subs{ii});
    dt6Dir = fullfile(subDir, dirs);
    fiberDir = fullfile(dt6Dir,'fibers');
    roiDir = fullfile(dt6Dir,'ROIs');

    disp(['Processing ' subDir '...']);

    if(~exist(fiberDir,'dir')), mkdir(fiberDir); end
    if(~exist(roiDir,'dir')), mkdir(roiDir); end

    dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
    fa = dtiComputeFA(dt.dt6);
    fa(fa>1) = 1; fa(fa<0) = 0;

    % If there is not a CC.mat ROI one will be created and saved.
    if exist(fullfile(dt6Dir,'ROIs','CC.mat'),'file');
        ccRoi = dtiRoiClean(dtiReadRoi(fullfile(roiDir,'CC.mat')), 3, {'fillHoles','dilate'});
    else
        disp('Finding CC... you should inspect this ROI');
        ccCoords = dtiFindCallosum(dt.dt6,dt.b0,dt.xformToAcpc);
        ccRoi = dtiNewRoi('CC','c',ccCoords);
        dtiWriteRoi(ccRoi, fullfile(roiDir,'CC.mat'));
        disp(['Writing ' ccRoi.name ' to ' roiDir]);
    end

    roiAll = dtiNewRoi('all');
    mask = fa>=faThresh;
    [x,y,z] = ind2sub(size(mask), find(mask));
    roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);

    % Make ROIs
    roiLeft = dtiRoiClip(roiAll, [-80 -5]);
    roiRight = dtiRoiClip(roiAll, [5 80]);

    clear roiAll;

    % Track Fibers
    disp('Tracking Left Hemisphere Fibers ...'); % Left
    fg = dtiFiberTrack(dt.dt6,roiLeft.coords,dt.mmPerVoxel,dt.xformToAcpc,'LFG',opts);
    fg = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
    fg = dtiCleanFibers(fg);
    fg = dtiFiberMidSagSegmentMIND(fg,nPts,'r'); % cuts fiber group so that only nPts remain on the opposite hem.
    fgL = fg;
    
    if merge == 0 || merge == 2
        if(fileFormat == 0)
            dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
        end
        if(fileFormat == 1)
            mtrExportFibers(fg,[fullfile(fiberDir,fg.name) '.pdb']);
        end
    else
    end
    clear fg;

    disp('Tracking Right Hemisphere Fibers ...'); % Right
    fg = dtiFiberTrack(dt.dt6,roiRight.coords,dt.mmPerVoxel,dt.xformToAcpc,'RFG',opts);
    fg = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
    fg = dtiCleanFibers(fg);
    fg = dtiFiberMidSagSegmentMIND(fg,nPts,'l');  % cuts fiber group so that only nPts remain on the opposite hem.
    fgR = fg;
    
    if merge == 0 || merge == 2
        if(fileFormat == 0)
            dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
        end
        if(fileFormat == 1)
            mtrExportFibers(fg,[fullfile(fiberDir,fg.name) '.pdb']);
        end
    else
    end
    clear fg;

    % Merge Fiber Groups
    if merge == 1 || merge == 2
        mergedFg = dtiMergeFiberGroups(fgL,fgR);
        if(fileFormat == 0)
            dtiWriteFiberGroup(mergedFg,fullfile(fiberDir,mergedFg.name));
        end
        if(fileFormat == 1)
            mtrExportFibers(mergedFg,[fullfile(fiberDir,mergedFg.name) '.pdb']);
        end
        disp(['The fiber group ' mergedFg.name ' has been written to ' fiberDir]);
        clear mergedFg;
    else
    end

    clear fgL;
    clear fgR;

end

disp('*************'); disp('  DONE!');




%%

%TEST
% baseDir = '/biac3/wandell7/data/MIND_Davis/FiberTracking/';
% subs = {'108378-100'};
% dirs = 'dti30trilinrt';




