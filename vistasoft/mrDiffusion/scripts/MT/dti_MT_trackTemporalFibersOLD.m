function dti_MT_trackTemporalFibersOLD
%
% This script will track temporal fibers using the Mori Temporal ROI and
% create an ROI on the callosum from those fiber's endpoints.
%
% Fibers will be generated with STT and all fibers in each hemisphere will
% be intersected with the callosal plane in the opposite hemisphere
% (CC_clipRight, CC_clipLeft, CC_clipMid). The other option is to take the
% central callosal plane and take the endpoints of the fibers and make an
% ROI from those fibers. 
%
% The large group of fibers will not be kept for each subject to conseve
% space. Only the temporal-callosal fiber group will be saved. 
% -----------------------------------------------------------------------
% Work List:
% 1. Track fibers (left and Right) 
% 2. Intersect with temporal ROI (Mori_[R/L]Temp.mat) and CC.mat (opposite
%    side of the hemisphere being tracked).
% 3. Save only those fibers CC<-->TemporalROI ******* Not with any other
%    MoriROI (maybe don't even save them)
%   3a. Clip the fibers so that only those fibers that are right at the
%       mid-sagital plane are retained.
% 4. Create an ROI from the fibers. (left and right)
% 5. Clip the ROI so that it includes only the central portion of the ROI
%    (x=0)
% 6. Save the ROI: CC_[L/R]Temp.mat
%    centerCoord = round(mean(roi.coords,1)*10)/10; % finds center of ROI
% 
%
% HISTORY:
% 2009.03.23 ... LMP wrote the thing.
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y1_old'};%,'dti_y2','dti_y3','dti_y4'}; 
 subs = {'tk0'};
% subs = {'am0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
%     'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
%     'sl0','sy0','tk0','tv0','vh0','vr0'};
fileFormat = 0; % 0 for .m, 1 for .pdb

%% Tracking Parameters
    faThresh = 0.35;
    opts.stepSizeMm = 1;
    opts.faThresh = 0.15;
    opts.lengthThreshMm = [50 250]; % was maxFiberLength
    opts.angleThresh = 60;
    opts.wPuncture = 0.2;
    opts.whichAlgorithm = 1;
    opts.whichInterp = 1;
    opts.seedVoxelOffsets = [0.25 0.75]; %.5; %

%% Loops through subs and tracks fibers

for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            dt6Dir = subDir;%, 'dti06');
            fiberDir = fullfile(dt6Dir,'fibers','MTproject');
            roiDir = fullfile(dt6Dir,'ROIs');
            mtRoiDir = fullfile(roiDir,'MTproject');
            if(~exist(fiberDir,'dir')), mkdir(fiberDir); end
            if(~exist(roiDir,'dir')), mkdir(roiDir); end
            if(~exist(mtRoiDir,'dir')), mkdir(mtRoiDir); end
            
            disp(['Processing ' subDir '...']);
            moriRoi = fullfile(roiDir,'Mori_LTemp.mat');

            % Load all ROIs
            if exist(moriRoi)
                lTempRoi = dtiReadRoi(fullfile(roiDir,'Mori_LTemp.mat'));
                rTempRoi = dtiReadRoi(fullfile(roiDir,'Mori_RTemp.mat'));
                ccRoi = dtiRoiClean(dtiReadRoi(fullfile(roiDir,'CC_FA.mat')), 3, {'fillHoles','dilate'});
                ccMidRoi = dtiReadRoi(fullfile(mtRoiDir,'CC_clipMid.mat'));

                dt = dtiLoadDt6(fullfile(dt6Dir,[sub.name,'_dt6_noMask.mat']));
                fa = dtiComputeFA(dt.dt6);
                fa(fa>1) = 1; fa(fa<0) = 0;

                roiAll = dtiNewRoi('all');
                mask = fa>=faThresh;
                [x,y,z] = ind2sub(size(mask), find(mask));
                roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);

                roiLeft = dtiRoiClip(roiAll, [0 80]);
                roiRight = dtiRoiClip(roiAll, [-80 0]);

                clear roiAll;


                %% LEFT HEMISPHERE
                disp('Tracking Left Hemisphere Fibers ...');

                fg = dtiFiberTrack(dt.dt6,roiLeft.coords,dt.mmPerVoxel,dt.xformToAcpc,'LFG',opts); % all fibers from LH
                fg = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
                fg = dtiCleanFibers(fg);

                fg = dtiIntersectFibersWithRoi([], {'and'},[],lTempRoi,fg); % fg is now only temporal-callosal fibers

                fg.name = 'LFG+CC+LTemp.mat';
                fg.colorRgb = [55 55 255];

                % Save the fibers
                if(fileFormat == 0), dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name)); end
                if(fileFormat == 1), dtiWriteFibersPdb(fg,dt.xformToAcpc,dt.mmPerVoxel,fullfile(fiberDir,fg.name)); end

                disp('...'); disp(['The fiber group ' fg.name ' has been written to ' fiberDir]); disp('...');

                % Create ROI from the endpoints of the clipped fiber group
                fg = dtiClipFiberGroup(fg,[-80 -1],[],[]); % clip left of the central plane
                fg = dtiClipFiberGroup(fg,[1 80],[],[]); % right. fg is now only the fibers at the central plane
                fg = dtiIntersectFibersWithRoi([],{'and'},[],ccMidRoi,fg); % take only the fibers on the CC

                lTempCCroi = dtiCreateRoiFromFiberEndPoints(fg);
                rTempCCroi.name = 'LTemp_CC.mat';
                lTempCCroi.color ='y';
                dtiWriteRoi(lTempCCroi,fullfile(mtRoiDir,'LTemp_CC.mat'));

                disp('...'); disp(['The ROI LTemp_CC.mat has been written to ' mtRoiDir]); disp('...');

                %% RIGHT HEMISPHERE
                disp('Tracking Right Hemisphere Fibers ...');

                fg = dtiFiberTrack(dt.dt6,roiRight.coords,dt.mmPerVoxel,dt.xformToAcpc,'RFG',opts);
                fg = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
                fg = dtiCleanFibers(fg);

                fg = dtiIntersectFibersWithRoi([], {'and'},[],rTempRoi,fg); % fg is now only temporal-callosal fibers

                fg.name = 'RFG+CC+RTemp.mat';
                fg.colorRgb = [255 55 55];

                % Save the fibers
                if(fileFormat == 0), dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name)); end
                if(fileFormat == 1), dtiWriteFibersPdb(fg,dt.xformToAcpc,dt.mmPerVoxel,fullfile(fiberDir,fg.name)); end

                disp('...'); disp(['The fiber group ' fg.name ' has been written to ' fiberDir]); disp('...');

                % Create ROI from the endpoints of the clipped fiber group
                fg = dtiClipFiberGroup(fg,[-80 -1],[],[]); % clip fibers left of the central plane
                fg = dtiClipFiberGroup(fg,[1 80],[],[]); % right. fg is now only the fibers at the central plane
                fg = dtiIntersectFibersWithRoi([],{'and'},[],ccMidRoi,fg); % take only the fibers on the CC

                rTempCCroi = dtiCreateRoiFromFiberEndPoints(fg);
                rTempCCroi.name = 'RTemp_CC.mat';
                rTempCCroi.color ='w';
                dtiWriteRoi(rTempCCroi,fullfile(mtRoiDir,'RTemp_CC.mat'));

                disp('...'); disp(['The ROI RTemp_CC.mat has been written to ' mtRoiDir]); disp('...');

                clear fg;
            else
                disp('No ROIs found. Skipping...');
            end
        else
            disp('No data found. Skipping...');
        end
    end
end

disp('*************');
disp('  DONE!');

return