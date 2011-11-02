% dti_STS_intersectFiberRois.m
%
% This simple script will load a group of fibers, create an ROI from those fibers,
% and intersect that ROI with another ROI, creating and saving a third ROI. 
%
% History:
% 2009.12.04 LMP wrote the thing.
%

%% Directory Structure
baseDir = '/biac3/wandell4/data/reading_longitude';
subs = {'at0','js0','md0','mh0','mho0','mm0','rh0','ss0'};
yr = {'dti_y3'};
dirs = 'dti06trilinrt';

fibers = {'Mori_LTemp_clean.mat','Mori_RTemp_clean.mat'};
rois = {'Mori_LTemp.mat','Mori_RTemp.mat'};

%% Work Loop
for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            dt6Dir = fullfile(subDir, dirs);
            fiberDir = fullfile(dt6Dir,'fibers');
            roiDir = fullfile(dt6Dir,'ROIs');

            if(~exist(roiDir,'dir')), mkdir(roiDir); end

            disp(['Processing ' subDir '...']);

           
            % Load ROI and Fibers
            for kk=1:numel(fibers)
                
                try fg = dtiReadFibers(fullfile(fiberDir,fibers{kk}));
                catch ME, fg = mtrImportFibers(fullfile(fiberDir,fibers{kk})); end
                
                fiberRoi = dtiCreateRoiFromFibers(fg);
                roi = dtiReadRoi(fullfile(roiDir,rois{kk}));
                intRoi = dtiIntersectROIs(fiberRoi,roi);
                intRoi.name = [intRoi.name 'ROI'];
                intRoi.color = [.1 1.0 .1];
                
                dtiWriteRoi(intRoi, fullfile(roiDir,intRoi.name));
       
            end
        else disp(['No data for ' subs{ii} ' in ' yr{jj}]);
        end
    end
end