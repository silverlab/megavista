% dti_MM_createCallosalRois
%
% This script takes a clean callosal fiber group and creates an
% roi at the central plane of the roi so that we can visualize where the
% fibers cross the CC. Code originally in dti_MT_trackTemporalFibers.m
% 
% HISTORY:
% 03.26.2009 LMP wrote the thing.
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_adults'};

subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311'...
    'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
    'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};

%%  Loops through subs
for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            dt6Dir = fullfile(subDir, 'dti06');
            fiberDir = fullfile(dt6Dir,'fibers','conTrack','occ_MORI_clean');
            roiDir = fullfile(dt6Dir,'ROIs');
            mRoiDir = fullfile(roiDir,'Mori_Contrack');
            if(~exist(mRoiDir,'dir')), mkdir(mRoiDir); end
            
            disp(['Processing ' subDir '...']);

            dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));

            %% Create ROI from the clipped fiber group
                      
            fiberGroups = {'Mori_Occ_CC_100k_top1000_LEFT_hom'...
                'Mori_Occ_CC_100k_top1000_RIGHT_hom'};
            
            c = 0;
            for kk=1:length(fiberGroups)
                c = (c+1);
                fg = dtiReadFibers(fullfile(fiberDir,[fiberGroups{kk} '.mat']));
                name = fg.name;
                fg = dtiClipFiberGroup(fg,[-80 -1],[],[]); % clip left of the central plane
                fg = dtiClipFiberGroup(fg,[1 80],[],[]); % right. fg is now only the fibers at the central plane

                % I'm wondering if at this point we should restrict the ROI to
                % the central most plane using dtiRoiClip - so that on the T1
                % the ROI is only 1 voxel wide instead of 3, as it is now. As
                % of now the ROI is one voxel wide in dti space, (~1.5).

                roi = dtiCreateRoiFromFibers(fg);

                if mod(c,2) == 0
                    roi.color = 'r';
                else
                    roi.color = 'b';
                end
                roi.name = [name,'_ccRoi'];

                dtiWriteRoi(roi,fullfile(mRoiDir,roi.name));

%                 disp([roi.name,' has been written to ' mRoiDir]);
            end


        else disp('No data for this subject in this year');
        end
    end

end
disp('Done!');