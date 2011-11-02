% dti_MM_clipCallosalFibers
%
% This script takes a clean MT-callosal fiber group and clips the fibers on
% the left and the right to only include those fibers that are within 5mm
% of the central plane.
%
% 1. This script will load the homotopic fibers from the left and the right.
% 2. Clip them so that only the 2cm closest to the central plane remains.
% 
% HISTORY:
% 04.3.2009 LMP wrote the thing.
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_adults'};
subs = {'aab050307'}; %,'ah051003','am090121','ams051015','as050307','aw040809','ct060309','db061209','dla050311','dl070825',...
%    'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
%    'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};

% subs = {'bw040922'};

%%  Loops through subs

for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            fiberDir = fullfile(subDir,'dti06','fibers','conTrack','occ_MORI_clean');
            if(~exist(fiberDir,'dir')), mkdir(fiberDir); end
            
            disp(['Processing ' subDir '...']);
            
            lOccFibers = fullfile(fiberDir,'Mori_Occ_CC_100k_top20000_LEFT.mat');
            rOccFibers = fullfile(fiberDir,'Mori_Occ_CC_100k_top20000_RIGHT.mat');
            
            if exist(lOccFibers) && exist(rOccFibers)
                disp('Fibers found.');

            % Clip Fibers around the midSagital plane
            nPts = 10; % default is 10
            
            % LEFT
            fg = dtiReadFibers(lOccFibers);
            newFg = dtiFiberMidSagSegment(fg,nPts);
                                   
%             dtiWriteFiberGroup(newFg,fullfile(fiberDir,newFg.name));
            
            disp('...'); disp(['The fiber group ' newFg.name ' has been written to ' fiberDir]); disp('...');
             
            % RIGHT
            fg = dtiReadFibers(rOccFibers);
            newFg = dtiFiberMidSagSegment(fg,nPts);
                        
%             dtiWriteFiberGroup(newFg,fullfile(fiberDir,newFg.name));

            disp('...'); disp(['The fiber group ' newFg.name ' has been written to ' fiberDir]); disp('...');
            
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
