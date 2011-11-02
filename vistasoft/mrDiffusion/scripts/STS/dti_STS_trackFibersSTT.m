% dti_STS_TrackFibers
% 
% 
% This script will:
%  1. Track all fibers in each subject's brain
%  2. Intersect those fibers with a given ROI 
%      The ROIs to be used are: 
%       Those coming from the STS - To be created by AK.
%  3. Save the fibers in .pdb or .m format.
%
%
%
%
% HISTORY: 
% 10.01.2009 - LMP wrote the thing. 

%% Directory Structure

baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y3'};
subs = {'rd0'};
dirs = 'dti06trilinrt'; % Directory that has the dt6.mat

fileFormat = 0; % 0 for .m, 1 for .pdb

% ROIs
leftRois = {'Mori_LSupPar','Mori_LTemp','Mori_LOcc'};
rightRois = {'Mori_RSupPar','Mori_RTemp','Mori_ROcc'};

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
    for dd=1:numel(yr)
        sub = dir(fullfile(baseDir,yr{dd},[subs{ii} '*']));
        subDir = fullfile(baseDir,yr{dd},sub.name);
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
        fg = dtiFiberMidSagSegment(fg,nPts,'r'); % cuts fiber group so that only nPts remain on the opposite hem.
        fgL = fg;
        for jj=1:numel(leftRois)
            try
            roi = dtiReadRoi(fullfile(roiDir,[leftRois{jj} '.mat']));
            fg = dtiIntersectFibersWithRoi([], {'and'}, [], roi, fgL);
            fg.name = [leftRois{jj} '+CC'];
            if(fileFormat == 0)
                dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
            end
            if(fileFormat == 1)
                dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
            end
            catch err
                disp([sub.name ': ' leftRois{jj} ' not found... skipping']);
            end
        end
        clear fgL

        disp('Tracking Right Hemisphere Fibers ...'); % Right
        fg = dtiFiberTrack(dt.dt6,roiRight.coords,dt.mmPerVoxel,dt.xformToAcpc,'RFG',opts);
        fg = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
        fg = dtiCleanFibers(fg);
        fg = dtiFiberMidSagSegment(fg,nPts,'l');  % cuts fiber group so that only nPts remain on the opposite hem.
        fgR = fg;
        for kk=1:numel(rightRois)
            try
            roi = dtiReadRoi(fullfile(roiDir,[rightRois{kk} '.mat']));
            fg = dtiIntersectFibersWithRoi([], {'and'}, [], roi, fgR);
            fg.name = [rightRois{kk} '+CC'];
            if(fileFormat == 0)
                dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
            end
            if(fileFormat == 1)
                dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
            end
           catch err
                disp([sub.name ': ' rightRois{jj} ' not found... skipping']);
            end
        end
        clear fgR

    end
end

disp('*************'); disp('  DONE!');















%%  
% MERGE the fiber groups
% merge = 0; % 0=do not merge fiber groups, 1=merge fiber groups, 2=save out both.

% if merge == 0 || merge == 2
%         if(fileFormat == 0)
%             dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
%         end
%         if(fileFormat == 1)
%             dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
%         end
%     else
%     end
%     clear fg;
% 
%  if merge == 0 || merge == 2
%         if(fileFormat == 0)
%             dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
%         end
%         if(fileFormat == 1)
%             dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
%         end
%     else
%     end
%     clear fg;
% 
%     % Merge Fiber Groups
%     if merge == 1 || merge == 2
%         mergedFg = dtiMergeFiberGroups(fgL,fgR);
%         mergedFg = dtiCleanFibers(mergedFg);
%         if(fileFormat == 0)
%             dtiWriteFiberGroup(mergedFg,fullfile(fiberDir,mergedFg.name));
%         end
%         if(fileFormat == 1)
%             dtiWriteFibersPdb(mergedFg,dt.xformToAcpc,fullfile(fiberDir,mergedFg.name));
%         end
%         disp(['The fiber group ' mergedFg.name ' has been written to ' fiberDir]);
%         clear mergedFg;
%     else
%     end
% 
%     clear fgL;
%     clear fgR;



