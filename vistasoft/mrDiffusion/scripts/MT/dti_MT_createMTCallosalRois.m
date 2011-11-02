% dti_MT_createMTCallosalRois
%
% This script takes a clean MT-callosal fiber group and creates an
% roi at the central plane of the roi so that we can visualize where the
% fibers cross the CC. See dti_MT_trackTemporalFibers.m (LMP)
% 
% HISTORY:
% 03.26.2009 LMP wrote the thing.
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y1'};%,'dti_y2','dti_y3','dti_y4'};
subs = {'ao0','am0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
    'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
    'sl0','sy0','tk0','tv0','vh0','vr0'};

stsRoi = {'lSTS_RvF','lSTS_RvI'};    
ccRoi = {'CC_clipMid'};

stsFg = {'scoredFG_STS_Callosum_lSTS_RvF_CC_clipRight_top1000_cleaned.pdb',...
    'scoredFG_STS_Callosum_lSTS_RvI_CC_clipRight_top1000_cleaned.pdb'};


%%  Loops through subs
for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            dt6Dir = fullfile(subDir, 'dti06');
            fiberDir = fullfile(dt6Dir,'fibers','conTrack');
            roiDir = fullfile(dt6Dir,'ROIs');
            if(~exist(fiberDir,'dir')), mkdir(fiberDir); end
            if(~exist(roiDir,'dir')), mkdir(roiDir); end

            disp(['Processing ' subDir '...']);

            ccMidRoi = dtiReadRoi(fullfile(roiDir,'MT',ccRoi));
            dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));


            %% Create ROI from the endpoints of the clipped fiber group1
            fg = dtiReadFibers(fullfile(fiberDir,stsFg{1}));
            fg = dtiClipFiberGroup(fg,[-80 -1],[],[]); % clip left of the central plane
            fg = dtiClipFiberGroup(fg,[1 80],[],[]); % right. fg is now only the fibers at the central plane
            fg = dtiIntersectFibersWithRoi([],{'and'},[],ccMidRoi,fg); % take only the fibers on the CC
            
            lTempCCroi = dtiCreateRoiFromFiberEndPoints(fg);
            lTempCCroi.color ='b';
            lTempCCroi.name = [stsRoi{1} '_CC_clean_roiClip.mat'];

            dtiWriteRoi(lTempCCroi,fullfile(roiDir,[stsRoi{1} '_CC_clean_roiClip.mat']));

            disp('...'); disp(['The ROI ' lTempCCroi.name, ' has been written to ' roiDir]); disp('...');


            %% RIGHT Create ROI from the endpoints of the clipped fiber group
            fg = dtiReadFibers(fullfile(fiberDir,stsFg{2}));
            fg = dtiClipFiberGroup(fg,[-80 -1],[],[]); % clip fibers left of the central plane
            fg = dtiClipFiberGroup(fg,[1 80],[],[]); % right. fg is now only the fibers at the central plane
            fg = dtiIntersectFibersWithRoi([],{'and'},[],ccMidRoi,fg); % take only the fibers on the CC
            
            rTempCCroi = dtiCreateRoiFromFiberEndPoints(fg);
            rTempCCroi.color ='r';
            rTempCCroi.name = 'RMT_CC_clean_roiClip.mat';
            dtiWriteRoi(rTempCCroi,fullfile(roiDir,'RMT_CC_clean_roiClip.mat'));

            disp('...'); disp(['The ROI RMT_CC_clean_roiClip.mat has been written to ' roiDir]); disp('...');
        else disp('No data for this subject in this year');
        end
    end

end
disp('Done!');