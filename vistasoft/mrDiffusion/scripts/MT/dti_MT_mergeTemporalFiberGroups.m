% dti_MT_mergeAndClipTemporalFiberGroups
%
% This script will load the segmented temporal fiber groups and merge them
% together, it will save the merged groups then clip them.
%
% History:
% 4/8/2009 LMP wrote the thing.
%
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y1'};%,'dti_y2','dti_y3','dti_y4'};
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
            fiberDir = fullfile(dt6Dir,'fibers');
            disp(['Processing ' subDir '...']);
            
            ccRoi = dtiReadRoi(fullfile(dt6Dir,'ROIs','CC.mat'));
            fg1 = dtiReadFibers(fullfile(fiberDir,'LTempCC_clean.mat'));
            fg2 = dtiReadFibers(fullfile(fiberDir,'RTempCC_clean.mat'));
            
            mergedFG = dtiMergeFiberGroups(fg1,fg2,'TempCC_clean');
            mergedFG.colorRgb = [138 43 226];
            mergedFG.name = 'TempCC_clean';
            
            dtiWriteFiberGroup(mergedFG,fullfile(fiberDir,'TempCC_clean.mat'));
            
            % Clip the fiber group
            fg = dtiReadFibers(fullfile(fiberDir,'TempCC_clean.mat'));
            fg = dtiClipFiberGroup(fg,[-80 -10],[],[]); % clip left of the central plane
            fg = dtiClipFiberGroup(fg,[10 80],[],[]);
            fg = dtiIntersectFibersWithRoi([],{'and'},[],ccRoi,fg);
            fg.colorRgb = [138 43 226];
            fg.name = 'TempCC_clean_20mmClip';
            
            dtiWriteFiberGroup(fg,fullfile(fiberDir,'TempCC_clean_20mmClip.mat'));

            disp('...'); disp(['The fiber group TempCC_clean_20mmClip.mat has been written to ' fiberDir]); disp('...');


                          
                       
        else
            disp('No data for this subject in this year');
        end
    end

end
disp('Done!');     