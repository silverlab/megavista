% dti_MoriBatchScript
% 
% This script will loop through a group of subjects and find their Mori
% Tracts using dtiFindMoriTracts.m. It will then run dtiCulFibers on the
% same group and save the fibers to the fiber directory. 
% 
%
% 2009.01.27 MP Wrote it
%2009.04.21 ER edited it to make sure dtiCullFibers uses explicitly stated
%parameters consistent across all the datasets in this project (since default values have
%been updated)

%% Set Directory Structure and Subject info 

projectName = 'MoriTracts';
batchDir = '/biac3/gotlib4/moriah/PINE/';
dtDir = 'anatomy/dti_analysis/dti25';
logDir = fullfile(batchDir,'dti_logs');
subs = {'BH','BT'};
fName = 'MoriTracts_Cull.mat';
cd(batchDir);

%% Start a log text file to document successes and failures in processing

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
if ~exist(logDir), mkdir(logDir); end
logFile = fullfile(logDir,[projectName, '_', dateAndTime '.txt']);
fid=fopen(logFile,'w');
startTime = clock;

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'dti_MoriBatchScript.m \n\nProcessing...\n\n');
% Print number of directories in group to log
disp(sprintf('\nWill find Mori Tracts for %d subjects. \n\n',length(subs)));
fprintf(fid,'\nWill find Mori Tracts for %d subjects. \n',length(subs));


timeStamp = datestr(now,30); %% Set the time once for the whole script
timeStamp(strfind(timeStamp,'T'))='_';
timeStamp=[timeStamp(1:4) '-' timeStamp(5:6) '-' timeStamp(7:11) '.' timeStamp(12:13) '.' timeStamp(14:15)];

fprintf(fid,'\nScript Time Stamp: %s\n\n',timeStamp);
fprintf(fid,'\n ------------------------------------------ \n');


%% Run the functions 

for ii=1:length(subs)
    fprintf(fid,'\n ------------------------------------------ \n');
    
    sub = dir(fullfile(batchDir,[subs{ii} '*']));
    subDir = fullfile(batchDir,sub.name);
    dt6Dir = fullfile(subDir, dtDir);
    fiberDir = fullfile(dt6Dir,'fibers');

    if ~exist(fiberDir), mkdir(fiberDir); disp(['Created fiber directory for ', subs{ii}]); end
    
    dt6 = fullfile(dt6Dir,'dt6.mat'); % Full path to dt6.mat
    
    % Fields printed to log file
                subCode = sub.name;
                [tmp subCode] = fileparts(subCode);
                fprintf('\nProcessing %s... \n',subCode);
                fprintf(fid,'\nProcessing %s... \n',subCode);
                fprintf(fid,'\t dt6 File: %s\n',dt6);
                    
    if exist(dt6)
                 disp(sprintf('\n Finding Mori Tracts for %s...', subs{ii}));
        fg = dtiFindMoriTracts(dt6); % this actually finds the Mori Groups
                fprintf(fid,'\n\t Found Mori Tracts for %s!', subs{ii});
                disp(sprintf('\n Culling Mori Tracts for %s...', subs{ii}));
                Tt=1;distanceCrit=1.7;
        fg = dtiCullFibers(fg, dt6, Tt, distanceCrit); % this culls the fiber groups
                fprintf(fid,'\n\t Cull Fibers complete for %s!', subs{ii});
        dtiWriteFiberGroup(fg,fullfile(fiberDir,fName)); % saves the fiber group to fiberDir
                fprintf(fid,'\t %s saved to: %s\n', fName, fiberDir);
        clear fg;
    else
        disp(sprintf('\n No dt6 for %s in %s! Skipping!', subs{ii}, dt6Dir));
        fprintf(fid,'\n No dt6 for %s in %s. Skipping!\n', subs{ii}, dt6Dir);
    end
end


%% Close things out

totalTime=etime(clock,startTime);

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);
fprintf('\n Script Completed in a total time of %f minutes\n',totalTime/60);
fclose(fid); % Close out the log file

return