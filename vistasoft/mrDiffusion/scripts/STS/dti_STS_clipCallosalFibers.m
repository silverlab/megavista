% dti_STS_clipCallosalFibers
%
% This script takes a clean XX-callosal fiber group and clips the fibers on
% the left and the right to only include those fibers that are within 5mm
% of the central plane.
%
% 1. This script will load the fibers {fgs}
% 2. Clip them so that only the nPts (in mm - default 10) closest to the
%    central plane remains. To do this dtiFiberMidSagSegment is used.
% 3. Save the resulting fibers (which are renamed in dtiFiberMidSagSegment)
%    as either .pdb or .mat. % 0=.mat, 1=.pdb:To retain scoring info must
%    be .pdb.

% HISTORY:
% 09.3.2009 LMP wrote the thing.
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y3'};
dtDir = 'dti06';
subs = {'at0','js0','md0','mh0','mho0','mm0','rh0','ss0'};
fgs = {'Mori_Temp_CC_top1000_LEFT.pdb', 'Mori_Temp_CC_top1000_RIGHT.pdb'};

fileFormat = 1; % 0=.mat, 1=.pdb
nPts = 10; % points to keep around the midSagital plane 

%%  Loops through subs

for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            fiberDir = fullfile(subDir,dtDir,'fibers','conTrack');
            if(~exist(fiberDir,'dir')), mkdir(fiberDir); end

            disp(['Processing ' subDir '...']);
            dt = dtiLoadDt6(fullfile(subDir,dtDir,'dt6.mat'));

            % Loop over fiber groups
            for ff = 1:numel(fgs)
                if exist(fgs{ff},'file'), disp('Fibers found.');
                    try fg = dtiReadFibers(fgs{ff});
                    catch ME, fg = mtrImportFibers(fgs{ff}); end
                    
                    % Segmentation of fiber points is done here:
                    newFg = dtiFiberMidSagSegment(fg,nPts);

                    if(fileFormat == 0), dtiWriteFiberGroup(newFg,fullfile(fiberDir,newFg.name)); end
                    if(fileFormat == 1), dtiWriteFibersPdb(newFg,dt.xformToAcpc,dt.mmPerVoxel,fullfile(fiberDir,newFg.name)); end

                    disp('...'); disp(['The fiber group ' newFg.name ' has been written to ' fiberDir]); disp('...');

                else disp([fgs{ff}, ' does not exist']);
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
