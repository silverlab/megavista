% dti_MT_clipTempCallosalFibers
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
yr = {'dti_y1'};%,'dti_y2','dti_y3','dti_y4'};
% subs = {'am0','ao0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
%     'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
%     'sl0','sy0','tk0','tv0','vh0','vr0'};
subs = {'sg0'};


%%  Loops through subs

for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            fiberDir = fullfile(subDir,'dti06','fibers','MT');
            if(~exist(fiberDir,'dir')), mkdir(fiberDir); end

            disp(['Processing ' subDir '...']);

            ff = {'scoredFG_MTproject_100k_200_5_top1000_LEFT_clean_hom.mat','scoredFG_MTproject_100k_200_5_top1000_RIGHT_clean_hom.mat'};

            for kk = 1:length(ff)
                fibers = fullfile(fiberDir,ff{kk});
                if exist(fibers)
                    disp('Fibers found.');

                    % Clip Fibers around the midSagital plane
                    nPts = 5; % default is 10
                    fg = dtiReadFibers(fibers);
                    newFg = dtiFiberMidSagSegment(fg,nPts);
                    
                    if kk ==1
                        newFg.colorRgb = [20 255 255];
                    end
                    if kk == 2 
                        newFg.colorRgb = [255 255 20];
                    end

                    dtiWriteFiberGroup(newFg,fullfile(fiberDir,newFg.name));

                    disp('...'); disp(['The fiber group ' newFg.name ' has been written to ' fiberDir]); disp('...');

                else disp([fibers, ' does not exist']);
                end
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
