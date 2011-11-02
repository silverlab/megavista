% ctr_MM_makeConTrackFiles
% 
% This script takes functions from ctrInit and makes the sampler.txt
% and .sh files (used by conTrack to generate fibers). This script makes those
% files for a group of subjects, across four data points
% and two differnt ROI pairs. The logFile reports the results of the
% process as well as the parameters used to setup the tracking script. 
%
% HISTORY:
% 12.09.2008: LMP Wrote the thing
% 


%% Set Directory Structure and Subject info
projectName = 'MT_CC_10k';
baseDir = '/biac3/wandell4/data/reading_longitude/';
logDir = fullfile(baseDir, 'dti_adults','ctr_controls','logs');
dtiYr = {'dti_adults'};
dtDir = 'dti06';

% subs = {'dl070825','am090121'};
% subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311',...
%    'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
%    'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};
% subs = {,'mm_temp040325'};

% subs = {'aab050307','aw040809','bw040922', 'gd040901','jm061209'...
%     'me050126','rfd040630','sd050527','sn040831','mm_temp040325'};

subs = {'aab050307','rfd040630'};

ROI1 = {'LMT','RMT'};
ROI2 = {'CC_clipRight','CC_clipLeft'};

%% Start a log text file to document successes and failures in preprocessing

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(logDir,[projectName, '_makeCtrScriptLog_', dateAndTime '.txt']);
fid=fopen(logFile,'w');
startTime = clock;

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Creating ctrScripts...\n\n');
% Print number of directories in age group to log
fprintf('\nWill make conTrack files for %d subjects \n\n',length(subs));
fprintf(fid,'\nWill make conTrack files for %d subjects: \n',length(subs));


%% Parameters set in ctrInit

nSamples = 10000; 
maxNodes = 240; %240
minNodes = 3;  %3
stepSize = 1;
pddpdfFlag = 0; % 0 = Only compute if file does not already exist. 1= Always recompute.
wmFlag = 0;  % 0 = Only compute if file does not already exist. 1= Always recompute.
roi1SeedFlag = 'true'; %1; % We always want to equally seed both ROIs, so both flags = 1.
roi2SeedFlag = 'true'; %0; % For speed we don't seed the second ROI (CC.mat)
timeStamp = datestr(now,30); %% Set the time once for the whole script
    timeStamp(strfind(timeStamp,'T'))='_';
    timeStamp=[timeStamp(1:4) '-' timeStamp(5:6) '-' timeStamp(7:11) '.' timeStamp(12:13) '.' timeStamp(14:15)];


fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'ctrInit Parameters:\n\n');
fprintf(fid,'\t Number of Samples: %d\n',nSamples);
fprintf(fid,'\t Max Nodes: %d\n',maxNodes);
fprintf(fid,'\t Min Nodes: %d\n',minNodes);
fprintf(fid,'\t Step Size: %d\n',stepSize);
fprintf(fid,'\t PDDPDF Flag (1=Always Compute): %d\n',pddpdfFlag);
fprintf(fid,'\t WM Flag (1=Always Compute): %d\n',wmFlag);
fprintf(fid,'\t ROI 1 Seed Flag (1=Seed ROI): %s\n',roi1SeedFlag);
fprintf(fid,'\t ROI 2 Seed Flag (1=Seed ROI): %s\n\n',roi2SeedFlag);
fprintf(fid,'\t Script Time Stamp: %s\n\n',timeStamp);
fprintf(fid,'\n ------------------------------------------ \n');


%% Create the ctrSampler and .sh files
c = 1; % Counter
for ii=1:length(subs)
    fprintf(fid,'\n ------------------------------------------ \n');
    % Loop through for each year of dti data
    for jj=1:length(dtiYr)
c = (c+1); % Counter
        sub = dir(fullfile(baseDir,dtiYr{jj},[subs{ii} '*']));
        if ~isempty(sub) % If there is no data for dtiYr{kk}, skip.
            subDir = fullfile(baseDir,dtiYr{jj},sub.name);
            dt6Dir = fullfile(subDir, dtDir);
            dt6 = fullfile(dt6Dir,'dt6.mat'); % Full path to dt6.mat
            
            roiDir = fullfile(dt6Dir,'ROIs');
            if ~exist(roiDir), mkdir(roiDir); disp('Created ROIs dir'); end

            fiberDir = fullfile(dt6Dir, 'fibers','conTrack');
            if ~exist(fiberDir), mkdir(fiberDir); disp('Created conTrack dir'); end
            
       
            for kk=1:length(ROI1)
                roi1 = fullfile(roiDir, [ROI1{kk},'.mat']);
                roi2 = fullfile(roiDir, [ROI2{kk},'.mat']); % For pairs of ROIs use ROI2{kk}
                fname = [ROI1{kk}, '_', ROI2{kk}];

                % Make the file
                params.roi1File     = roi1;
                params.roi2File     = roi2;
                params.dt6File      = dt6;
                params.dSamples     = nSamples;
                params.maxNodes     = maxNodes;
                params.minNodes     = minNodes;
                params.stepSize     = stepSize;
                params.pddpdf       = pddpdfFlag;
                params.wm           = wmFlag;
                params.seedRoi1     = roi1SeedFlag;
                params.seedRoi2     = roi2SeedFlag;
                params.timeStamp    = timeStamp; % See subFunction below

                % Fields printed to log file
                subCode = sub.name;
                [tmp subCode] = fileparts(subCode);
                fprintf('\nProcessing %s... \n',subCode);
                fprintf(fid,'\nProcessing %s... \n',subCode);
                fprintf(fid,'\t dt6 File: %s\n',dt6);
                fprintf(fid,'\t ROI pair: %s\n',fname);
                fprintf(fid,'\t\t ROI 1: %s\n',roi1);
                fprintf(fid,'\t\t ROI 2: %s\n',roi2);

                % This does ALMOST EVERYTHING
                % 1. Creates wmprob.nii.gz
                % 2. Creates pdf.nii.gz
                % 3. Create ROI mask.nii.gz
                % 4. Create the ctrSampler_timestamp.txt file
                % 5. Create the ctrScript_timestamp.sh file
                samplerName = ['ctrSampler_',projectName,'_',fname,'_',timeStamp,'.txt'];
                samplerName = fullfile(fiberDir,samplerName);

                params = ctrInitParamsFile(params,samplerName);
                fprintf(fid,'\t ctr.txt: %s\n',samplerName);

                bashName = ['ctrScript_',projectName,'_',fname,'_',timeStamp,'.sh'];
                bashName = fullfile(fiberDir,bashName);
                
                [tmp,roi1] = fileparts(params.roi1File);
                [tmp,roi2] = fileparts(params.roi2File);
                outFile = ['fg_',projectName,'_',roi1,'_',roi2,'_',timeStamp,'.pdb'];
                
                ctrScript(params,bashName,outFile);
                
                fprintf(fid,'\t ctr.sh: %s\n',bashName);

            end

        else
            disp(sprintf(['\n No data for ' subs{ii} ' in '  dtiYr{jj} '! Skipping.']));
            fprintf(fid,'\n No data for %s in %s. Skipping!\n', subs{ii}, dtiYr{jj});
        end
    end
end

%% Close things out

totalTime=etime(clock,startTime);

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);

fprintf('\n Script Completed in a total time of %f minutes\n',totalTime/60);

% Write script used into the log
% newfid = fopen(which('ctr_MT_makeConTrackFiles.m'), 'r');
% code = fread(newfid); fclose(newfid);
% code = char(code);
% fprintf(fid, '\n\n-----------------------\n%s', code);
% fclose(newfid); 

fclose(fid); % Close out the log file

return
