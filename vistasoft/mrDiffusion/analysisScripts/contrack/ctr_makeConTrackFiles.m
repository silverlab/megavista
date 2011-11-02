% ctr_makeConTrackFiles
% 
% This script takes functions from ctrInit and makes the sampler.txt and
% .sh files (used by conTrack to generate fibers). 
%
% This script makes those files for a group of subjects, across data points
% and differnt ROI pairs. 
% 
% The logFile reports the results of the process as well as the parameters
% used to setup the tracking script.
% 
% A infoFile (info) is also created for use with ctr_conTrackBatchScore.m
% 
% What you end up with here is (1) a log file, (2) a log.mat file (for use with ctr_conTrackBatchScore, and (3)
% a .sh shell script that will be displayed in the command window, which will run
% tracking for all subjects and ROIs specified. The resulting .sh file (3)
% should be run on a 64-bit linux machine with plenty of power. 
%
% 
% HISTORY: 
% 08.27.2009: LMP Wrote the thing
% 09.28.2009: LMP added fileFormat to allow the user to choose which file
% format the superSet of fibers will be saved out as.


%% Set Directory Structure and Subject info
scriptName = 'makeCtrFiles';
projectName = 'LGIGH';
logName = '3mm_5mm_10mm_100k'; % Give the logFile a unique name for easy ID.

baseDir = '/biac3/wandell7/data/ECoG/ecog04';
dtiYr = {'mri'};
subs = {'dti'};
dtDir = 'dti40';

logDir = fullfile(baseDir,'conTrackProject','logs');
scrDir = fullfile(baseDir,'conTrackProject','shellScripts');

multiThread = 1; % 1 = execute all tracking simultaneously, 0 = use only 3 cores.
fileFormat = '.pdb'; % Choose .pdb or .Bfloat.


% ROIS - No extensions
ROI1 = {'RLG6_3mm_RLG7_3mm','RLG6_5mm_RLG7_5mm','RLG6_10mm_RLG7_10mm'};    
ROI2 = {'RIGH16_3mm_RIGH17_3mm','RIGH16_5mm_RIGH17_5mm','RIGH16_10mm_RIGH17_10mm'};

  
%% Parameters Set In ctrInit

nSamples = 100000; 
maxNodes = 240;                     
minNodes = 3;                   
stepSize = 1;
pddpdfFlag = 0;                 % 0 = Only compute if file does not already exist. 1= Always recompute.
wmFlag = 0;                     % 0 = Only compute if file does not already exist. 1= Always recompute.
roi1SeedFlag = 'true';          % 1; % We always want to equally seed both ROIs, so both flags = 1.
roi2SeedFlag = 'true';          % 0; % For speed we don't seed the second ROI (CC.mat)
timeStamp = datestr(now,30);    % Set the time once for the whole script
timeStamp(strfind(timeStamp,'T'))='_';
timeStamp=[timeStamp(1:4) '-' timeStamp(5:6) '-' timeStamp(7:11) '.' timeStamp(12:13) '.' timeStamp(14:15)];



%%%%%%%%%%%%%%%%% Don't Edit Below %%%%%%%%%%%%%%%%%%%%%%%


%% Create log and batchScript files 

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
startTime = clock;

if ~exist(logDir), mkdir(logDir); disp('Created log dir'); end
if ~exist(scrDir), mkdir(scrDir); disp('Created Shell Script Directory'); end

logFileName = fullfile(logDir,[projectName,'_',logName, '_ctrMakeLog_', dateAndTime]);
logFile = [logFileName, '.txt'];
fid = fopen(logFile,'w');

%% Start writing the batch File that will run all resulting .sh files

batchFileName = fullfile(scrDir,[projectName, '_ctrGenBatchShellScript_', dateAndTime '.sh']);
fid2 = fopen(batchFileName, 'w');
fprintf(fid2, '\n#!/bin/bash');
fprintf(fid2, '\n# Log file used: %s \n', logFile);

%% Create info file that will be loaded for scoring - same name as log file

    info.projectName = projectName;
    info.baseDir = baseDir;
    info.dtiYr = dtiYr;
    info.subs = subs;
    info.dtDir = dtDir;
    info.roi1 = ROI1;
    info.roi2 = ROI2;
    info.logDir = logDir;
    info.scrDir = scrDir;
    info.timeStamp = timeStamp;
    info.nSamples = nSamples;

    infoFile = [logFileName,'.mat'];
    save(infoFile,'info');
    
    %% Log File: Print params to log and info file
    
    fprintf(fid,'Info File: \n %s\n',infoFile);
    fprintf(fid,'\n ------------------------------------------ \n');
    fprintf(fid,'\nWill make conTrack files for %d subjects: \n',numel(subs));
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
    fprintf(fid,'\n ------------------------------------------ \n');
    fprintf('\nWill make conTrack files for %d subjects. \n\n',numel(subs));

   %% Create the ctrSampler and .sh files
    c = 0; % Initialize counter

for ii=1:numel(subs)
    fprintf(fid,'\n ------------------------------------------ \n');
    fprintf(fid2,'\n');
    
    for jj=1:numel(dtiYr)
       
       sub = dir(fullfile(baseDir,dtiYr{jj},[subs{ii} '*']));
        if ~isempty(sub) % If there is no data for dtiYr{kk}, skip.
            subDir = fullfile(baseDir,dtiYr{jj},sub.name);
            dt6Dir = fullfile(subDir,dtDir);
            dt6 = fullfile(dt6Dir,'dt6.mat'); % Full path to dt6.mat
            
            roiDir = fullfile(dt6Dir,'ROIs');

            fiberDir = fullfile(dt6Dir,'fibers','conTrack');
            if ~exist(fiberDir,'file'), mkdir(fiberDir); disp('Created conTrack dir...'); end

            c = (c+1); % counter
       
            for kk=1:numel(ROI1)
                roi1 = fullfile(roiDir, [ROI1{kk},'.mat']);
                if numel(ROI2) == 1
                roi2 = fullfile(roiDir, [ROI2{:},'.mat']); % For pairs of ROIs use ROI2{kk}
                fname = [ROI1{kk}, '_', ROI2{:}];
                else 
                roi2 = fullfile(roiDir, [ROI2{kk},'.mat']); % For pairs of ROIs use ROI2{kk}
                fname = [ROI1{kk}, '_', ROI2{kk}];
                end

                % Make the params struct 
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
                params.timeStamp    = timeStamp; 
                
                % Fields printed to log file
                subCode = sub.name;
                fprintf('\nProcessing %s... \n',subCode);
                fprintf(fid,'\nProcessing %s... \n',subCode);
                fprintf(fid,'\t dt6 File: %s\n',dt6);
                fprintf(fid,'\t ROI pair: %s\n',fname);
                fprintf(fid,'\t\t ROI 1: %s\n',roi1);
                fprintf(fid,'\t\t ROI 2: %s\n',roi2);

                % This does ALMOST EVERYTHING
                samplerName = ['ctrSampler_',projectName,'_',fname,'_',timeStamp,'.txt'];
                samplerName = fullfile(fiberDir,samplerName);

                params = ctrInitParamsFile(params,samplerName);
                fprintf(fid,'\t ctr.txt: %s\n',samplerName);

                bashName = ['ctrScript_',projectName,'_',fname,'_',timeStamp,'.sh'];
                bashName = fullfile(fiberDir,bashName);
                                               
                [tmp,roi1] = fileparts(params.roi1File);
                [tmp,roi2] = fileparts(params.roi2File);
                
                % Set the name for the superSet of fibers.
                outFile = ['fg_',projectName,'_',roi1,'_',roi2,'_',timeStamp,fileFormat];
                
                %Creates the .sh file
                ctrScript(params,bashName,outFile);
                
                fprintf(fid,'\t ctr.sh: %s\n',bashName);
                
                % Writes the command to the batchShFile
                fprintf(fid2,'\n\ncd %s',fiberDir); % Change to the conTrack dir before running the .sh.
                
                if multiThread == 0
                    if mod(c,4) ~= 0
                        fprintf(fid2, '\n%s &', bashName);
                    else 
                        fprintf(fid2, '\n%s', bashName);
                    end
                else
                    fprintf(fid2, '\n%s &', bashName);
                end
            end

        else
            disp(sprintf(['\n No data for ' subs{ii} ' in '  dtiYr{jj} '! Skipping.']));
            fprintf(fid,'\n No data for %s in %s. Skipping!\n', subs{ii}, dtiYr{jj});
        end
    end
end

%% Close things out

totalTime = etime(clock,startTime);

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);

fprintf('\n Script Completed in a total time of %f minutes\n',totalTime/60);

% Write script used into the log
newfid = fopen(which(scriptName), 'r');
code = fread(newfid); fclose(newfid);
code = char(code);
fprintf(fid, '\n\n-----------------------\n%s', code);

fclose(fid); % Close out the log file
fclose(fid2); % Close out the log file

% Edit permissions of the .sh file (batchFileName) so that it can be executed.
[status,result] = system(['chmod 775 ' batchFileName]);
if status ~= 0
    disp(['chmod failure. Permissions need to be edited manually for ' batchFileName]);
end

% Display in the command window the command that can be copied and pasted
% in a terminal to run all of the .sh files.
cd(scrDir);
fprintf('\n...\nCopy and paste the following line of code into your shell to execute all of the .sh files and initiate tracking: \n. %s \n', batchFileName);

return
