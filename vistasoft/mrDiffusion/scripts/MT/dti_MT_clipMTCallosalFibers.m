% dti_MT_clipMTCallosalFibers
%
% This script takes a clean MT-callosal fiber group and clips the fibers on
% the left and the right to only include those fibers that are within 5mm
% of the central plane.
%
% 1. This script will load the homotopic fibers from the left and the right.
% 2. Clip them so that only the 5mm closest to the central plane remains.
% 
% HISTORY:
% 04.3.2009 LMP wrote the thing.
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y1'}; %,'dti_y2','dti_y3','dti_y4'};
 subs = {'ao0','am0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
    'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
    'sl0','sy0','tk0','tv0','vh0','vr0'};


%%  Loops through subs
for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            dt6Dir = fullfile(subDir, 'dti06');
            fiberDir = fullfile(dt6Dir,'fibers','MT');
            roiDir = fullfile(dt6Dir,'ROIs');
            if(~exist(fiberDir,'dir')), mkdir(fiberDir); end
            if(~exist(roiDir,'dir')), mkdir(roiDir); end

            disp(['Processing ' subDir '...']);

            dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));


            %% LEFT 
            fg = dtiReadFibers(fullfile(fiberDir,'scoredFG_MTproject_100k_200_5_top1000_LEFT_clean_hom.mat'));
            fg = dtiClipFiberGroup(fg,[-80 -5],[],[]); % clip left of the central plane
            fg.colorRgb = [20 20 255];
            fg.name = 'LMT_CC_clean_hom_5mmClip.mat';
            
            dtiWriteFiberGroup(fg,fullfile(fiberDir,'LMT_CC_clean_hom_5mmClip.mat'));

            disp('...'); disp(['The fiber group LMT_CC_clean_hom_5mmClip.mat has been written to ' fiberDir]); disp('...');


            %% RIGHT 
            fg = dtiReadFibers(fullfile(fiberDir,'scoredFG_MTproject_100k_200_5_top1000_RIGHT_clean_hom.mat'));
            fg = dtiClipFiberGroup(fg,[5 80],[],[]); % clip fibers left of the central plane
            fg.colorRgb = [255 20 20];
            fg.name = 'RMT_CC_clean_hom_5mmClip.mat';
            
            dtiWriteFiberGroup(fg,fullfile(fiberDir,'RMT_CC_clean_hom_5mmClip.mat'));
            
            disp('...'); disp(['The fiber group LMT_CC_clean_hom_5mmClip.mat has been written to ' fiberDir]); disp('...');
        else disp('No data for this subject in this year');
        end
    end

end
disp('Done!');