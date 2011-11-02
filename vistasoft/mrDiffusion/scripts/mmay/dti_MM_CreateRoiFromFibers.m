% dti_MM_clipCallosalFibers
%
% This script takes a fiber group and creates an ROI from those fibers.
% 
% HISTORY:
% 05.12.2009 LMP wrote the thing.
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_adults'};

subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311',...
   'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
   'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};

% subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','ct060309','db061209','dl070825','dla050311',...
%    'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
%    'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};


%%  Loops through subs

for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            fiberDir = fullfile(subDir,'dti06','fibers','conTrack','occ_MORI_clean');
            roiDir = fullfile(subDir,'dti06','ROIs','Mori_Contrack');
            if(~exist(fiberDir,'dir')), mkdir(fiberDir); end
            
            disp(['Processing ' subDir '...']);
            
            lOccFibers = fullfile(fiberDir,'Mori_Occ_CC_100k_top1000_LEFT.mat');
            rOccFibers = fullfile(fiberDir,'Mori_Occ_CC_100k_top1000_RIGHT.mat');
            
            if exist(lOccFibers,'file') && exist(rOccFibers,'file')
                disp('Fibers found.');

            % Create Left ROI
            fg = dtiReadFibers(lOccFibers);
            roi = dtiCreateRoiFromFibers(fg);  
            dtiWriteRoi(roi,fullfile(roiDir,roi.name));
            
            disp(['The roi ' roi.name ' has been written to ' roiDir]); disp('...');
             
            % Create Right ROI
            fg = dtiReadFibers(rOccFibers);
            roi = dtiCreateRoiFromFibers(fg);
            dtiWriteRoi(roi,fullfile(roiDir,roi.name));
            
            disp(['The roi ' roi.name ' has been written to ' roiDir]); disp('...');
            
            else disp([lOccFibers, ' does not exist']);
            end
        else disp('No data for this subject in this year');
        end
    end

end
disp('Done!');




%%



















































%% Old Code
%             % LEFT 
%             fg = dtiReadFibers(fullfile(fiberDir,'TempCC_clean.mat'));
%             fg = dtiClipFiberGroup(fg,[-80 -10],[],[]); % clip left of the central plane
%             fg = dtiClipFiberGroup(fg,[10 80],[],[]);
%             fg = dtiIntersectFibersWithRoi([],{'and'},[],ccRoi,fg);
%             fg.colorRgb = [20 255 255];
%             fg.name = 'TempCC_clean_20mmClip';
%             
%             dtiWriteFiberGroup(fg,fullfile(fiberDir,'TempCC_clean_20mmClip.mat'));
% 
%             disp('...'); disp(['The fiber group TempCC_clean_20mmClip.mat has been written to ' fiberDir]); disp('...');
% 
% 
% %             %% RIGHT 
%             fg = dtiReadFibers(fullfile(fiberDir,'RTempCC_clean.mat'));
%             fg = dtiClipFiberGroup(fg,[5 80],[],[]); % clip fibers left of the central plane
%             fg = dtiClipFiberGroup(fg,[-80 -1],[],[]);
%             fg.colorRgb = [255 255 40];
%             fg.name = 'RTempCC_clean_5mmClip';
%             
%             dtiWriteFiberGroup(fg,fullfile(fiberDir,'RTempCC_clean_5mmClip.mat'));
%             
%             disp('...'); disp(['The fiber group RTempCC_clean_5mmClip.mat has been written to ' fiberDir]); disp('...');
%        
%         
