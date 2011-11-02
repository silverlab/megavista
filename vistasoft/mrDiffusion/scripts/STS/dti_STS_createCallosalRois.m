% dti_STS_createCallosalRois
%
% This script takes a clean callosal fiber group and creates an
% roi at the central plane so that we can visualize where the
% fibers cross the CC. The script will clip the fibers first. 
% 
% HISTORY:
% 03.26.2009 LMP wrote the thing.
% 09.02.2009 LMP - updates to structure
% 09.05.09 LMP - now uses dtiFiberMidSagSegment to clip the fg to nPts
% around the midSagitalPlane. Then we create an ROI from those fibers and
% clip it so that it only includes the midSagitalPlane (1mm). 
%

%% directory structure and flags
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y3'};
subs = {'at0','js0','md0','mh0','mho0','mm0','rh0','ss0'};

stsFg = {'Mori_LOcc_clean.mat','Mori_ROcc_clean.mat','Mori_LTemp_clean.mat', ...
    'Mori_RTemp_clean.mat','Mori_LSupPar_clean.mat','Mori_RSupPar_clean.mat'};

fileFormat = 0; % 0=.mat, 1=.pdb
nPts = 10; % points to keep around the midSagital plane 

%%  
for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            dt6Dir = fullfile(subDir, 'dti06trilinrt');
            fiberDir = fullfile(dt6Dir,'fibers');
            roidir = fullfile(dt6Dir,'ROIs');

            if(~exist(roidir,'dir')), mkdir(roidir); end

            disp(['Processing ' subDir '...']);

            dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));

            % Create clip fibers around the midPoint and create ROI from the clipped fiber group
            c = 0;
            for kk=1:length(stsFg)
                c = (c+1);
                
                try fg = dtiReadFibers(fullfile(fiberDir,stsFg{kk}));
                catch ME, fg = mtrImportFibers(fullfile(fiberDir,stsFg{kk})); end
                
                name = fg.name;
               
                newFg = dtiFiberMidSagSegment(fg,nPts);  % Segmentation of fiber points is done here

                if(fileFormat == 0), dtiWriteFiberGroup(newFg,fullfile(fiberDir,newFg.name)); end
                if(fileFormat == 1), dtiWriteFibersPdb(newFg,dt.xformToAcpc,dt.mmPerVoxel,fullfile(fiberDir,newFg.name)); end

                disp('...'); disp(['The fiber group ' newFg.name ' has been written to ' fiberDir]); disp('...');
                
                % Create ROI and clip to only include the midSagitalPlane (1mm)
                roi = dtiCreateRoiFromFibers(newFg);
                
                [centerCC roiNot] = dtiRoiClip(roi, [1 80], [], []);
                [newCC roiNot] = dtiRoiClip(centerCC, [-80 -1], [], []);
                roi = newCC;
                if mod(c,2) == 0, roi.color = 'r'; else roi.color = 'b'; end
                roi.name = [name '_CCroi'];

                dtiWriteRoi(roi,fullfile(roidir,roi.name));

                disp('...'); disp([roi.name,' has been written to ' roidir]); disp('...');
                clear fg; 
                clear newFg;
            end


        else disp('No data for this subject in this year');
        end
    end

end
disp('Done!');