% This script loops through a group of subjects, loads a specified ROI and
% cleans the ROI and saves it with a new name. 
%
% HISTORY:
% 01.08.2009 MP Wrote it.
%

baseDir = '/biac3/wandell4/data/reading_longitude/';
dtiYr = {'dti_y1','dti_y2','dti_y3','dti_y4'};
dt = 'dti06';
ROIs = {'LMT.mat','RMT.mat'};
newName = 'clean_';
subs = {'ao0','am0', 'bg0','crb0','ctb0'};
% subs = {'ao0','am0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
%             'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
%             'sl0','sy0','tk0','tv0','vh0','vr0'};


%% Initialize a logfile to keep track of subjects and ROIs. 
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(baseDir,'MT_Project','logs',['MT_log_cleanDilateROIs_', dateAndTime,'.txt']);
fid = fopen(logFile, 'w');

fprintf(fid,'  \n  cleaning MT ROIs for %d subjects: %s', length(subs), date); 
fprintf(fid,'\n************************************************ \n');
fprintf(fid,'Subs: \r');
fprintf(fid, '  %s,', subs{:});
fprintf(fid, '\nROIs: \r');
fprintf(fid, '  %s \n', ROIs{:});
fprintf(fid, '\nSmoothing kernel: 3');
fprintf(fid, '\nFill Holes: 1');
fprintf(fid, '\nRemove Sat: 1');
fprintf(fid, '\nDilate: 1');
fprintf(fid,'\n************************************************ \n');


% Do the Work
for ii=1:length(subs)

    fprintf(fid,'\n------------------------------------------ \n');
    fprintf(fid, 'Subject: %s \r',subs{ii});
    
    for kk=1:length(dtiYr)
        dSubDir = dir(fullfile(baseDir,dtiYr{kk},[subs{ii} '*']));
        if ~isempty(dSubDir) % If there is no data for dtiYr{kk}, skip.
            dSubDir = fullfile(baseDir,dtiYr{kk},dSubDir.name);
            dt6Dir = fullfile(dSubDir,dt);
            dt6file = fullfile(dt6Dir,'dt6.mat');
            roiDir = fullfile(dt6Dir,'ROIs','MT');
            if(~isdir(roiDir)), mkdir(roiDir); end

            % Clean the ROIs for each sub for each year
            for ll=1:length(ROIs)
                cleanRoiName = [newName, ROIs{ll}];
                roi = dtiReadRoi(fullfile(roiDir,ROIs{ll}));
                % Actual cleaning and saving is done here
                newRoi = dtiRoiClean(roi, [3 3 3], [{'fillhole', 'removesat', 'dilate'}]);
                newRoi.name = cleanRoiName;
                newRoi.color = 'y';
                dtiWriteRoi(newRoi, fullfile(roiDir, cleanRoiName));

                disp(sprintf(['\n**Now cleaning and dilating ROIs for ' subs{ii} ' in '  dtiYr{kk} '...']));
                fprintf(fid, 'Cleaned %s for: %s %s: Saved %s to: %s  \r', ROIs{ll}, subs{ii}, dtiYr{kk}, cleanRoiName, roiDir);
            end
        else
            disp(sprintf(['\n No data for ' subs{ii} ' in '  dtiYr{kk} '! Skipping.']));
            fprintf(fid,'\n** No data for %s in %s. Skipping. \n', subs{ii},dtiYr{kk});
        end
    end
end

fprintf(fid,'\n\n*******\n DONE!\n*******\n');
fclose(fid); % Close out the log file.
disp(sprintf('\n*******\n DONE!\n*******'));






