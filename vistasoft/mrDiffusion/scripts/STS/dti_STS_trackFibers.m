% dti_STS_TrackFibers
% 
% This script takes a group of subjects in subCodeList (a text File) and: 
% 1.  Tracks all fibers in each hemisphere (sep). 
% 2.  Intersects those fibers with the STS ROI as defined anatomically by
%     AK.
% 3.  Save the fiber groups in .pdb format so that the fibers can be
%     loaded in Quench. Or .m.  
% 
%
% HISTORY: 
% 01.19.2010 - LMP wrote the thing. 
% 11.30.2010 - LMP general updated to track from the CC to the Angular
%              Gyrus.
%% Directory Structure

baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y1'};
subs ={'ab0','ad0','ada0','ajs0','am0','an0','ao0','ar0','at0','bg0','ch0','clr0','cp0',...
    'crb0','ctb0','ctr0','da0','dh0','dm0','es0','hy0','jh0','js0','jt0','kj0','ks0',...
    'lg0','ll0','mb0','md0','mh0','mho0','mm0','mn0','nad0','nf0','nid0','pf0','pt0',...
    'rd0','rh0','rs0','rsh0','sg0','sl0','ss0','sy0','tk0','tm0','tv0','vh0','vr0','vt0','zs0','lj0'};
dirs = 'dti06trilinrt'; 

fileFormat = 1; % 0 for .m, 1 for .pdb

% ROIs and CC fibers - no extensions
rois = {'Brocas'}; % AngularGyrus
ccFibers = 'allLeftFG+CC.mat';

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
        
        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
        ccFg = fullfile(fiberDir,ccFibers);
        
        if exist(ccFg,'file')
            fprintf('CC Fibers found. No need to track...\n');
            ccFg = dtiReadFibers(ccFg);
            for jj=1:numel(rois)
                try
                    roi = dtiRoiClean(dtiReadRoi(fullfile(roiDir,[rois{jj} '.mat'])),[3 3 3],'dilate');
                    fg = dtiIntersectFibersWithRoi([], {'and'}, [], roi, ccFg);
                    fg.name = [rois{jj} '+CC'];
                    if numel(fg.fibers) >=1
                        if(fileFormat == 0)
                            dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
                        end
                        if(fileFormat == 1)
                            dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
                        end
                    else
                        fprintf('Fiber group is EMPTY!!! Not Saving empty group!\n\n');
                    end
                catch err
                    disp([sub.name ': ' rois{jj} ' not found... skipping']);
                end
            end
            clear fg ccFg
            
        else fprintf('\n\nFibergroup %s does not exist... \nTracking fibers...\n',ccFg);
            
            fa = dtiComputeFA(dt.dt6);
            fa(fa>1) = 1; fa(fa<0) = 0;
            
            roiAll = dtiNewRoi('all');
            mask = fa>=faThresh;
            [x,y,z] = ind2sub(size(mask), find(mask));
            roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);
            ccRoi = dtiRoiClean(dtiReadRoi(fullfile,roiDir,'CC.mat'),[3 3 3],'dilate');
            fg = dtiFiberTrack(dt.dt6,roiAll.coords,dt.mmPerVoxel,dt.xformToAcpc,'AllFG',opts);
            for jj=1:numel(rois)
                try
                    roi = dtiRoiClean(dtiReadRoi(fullfile(roiDir,[rois{jj} '.mat'])),[3 3 3],'dilate');
                    fg = dtiIntersectFibersWithRoi([], {'and'}, [], roi, fg);
                    fg = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
                    fg.name = [rois{jj} '+CC'];
                    if numel(fg.fibers) >=1
                        if(fileFormat == 0)
                            dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
                        end
                        if(fileFormat == 1)
                            dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
                        end
                    else
                        fprintf('Fiber group is EMPTY!!! Not Saving empty group!\n\n');
                    end
                catch err
                    disp([sub.name ': ' rois{jj} ' not found... skipping']);
                end
            end
            clear fg
        end
        
        
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



