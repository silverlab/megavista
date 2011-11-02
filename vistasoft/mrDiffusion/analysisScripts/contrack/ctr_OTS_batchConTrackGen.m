function ctr_MT_batchConTrackGen(logFileName, shName, batchDir)
% Usage: ctr_MT_batchConTrackGen([logFileName], [shName], [batchDir])
%
% This script loops through a list of subjects and creates a .sh file that
% will run their ctrScript.sh files. It assumes that all subjects will
% have the exact same .sh file name. If logFileName and/or shName are not
% specified a GUI will open that will allow you to browse for them. 
%
% This script will output to the screen the full path and file name for the
% .sh file that will run all of the ctrScripts. 
% 
% 2008.12.15 MP reworked the script to work with the longitudinal data from ctr_FFA.
%

%%
% Add a project name to the .sh file for easy id.
projectName = 'Broca_OTS_Vinckier';
% hem = 'LEFT';
%  hem = 'RIGHT';
 hem = '';

% Set batch directory and change to that directory for easy navigation.
batchDir = '/biac3/wandell4/data/reading_longitude/';
ssDir = fullfile(batchDir, 'dti_adults','OTS_Broca','shellScripts');
dtiYr = {'dti_adults'};
dtDir = 'dti40';
subs = {'rfd080930'};

cd(batchDir);


%%
% Allow user to specify the log file (or not) that contains parameters to
% be used by conTrackGen. These are typically specified in
% ctr_MT_makeConTrackFiles.  
if notDefined('logFileName')
    logFileName = specifyExistingLogfileToCopy; 
end

% All sh files created by ctr_FFA_createConTrackFiles will have the same
% name. Therefore all the user should do is specify an sh file name by
% choosing it from an example subject. 
if notDefined('shName')
    shName = specifyShName;
end

% Specify batchDir, which is the directory that should contain a list of
% all the subjects directories to process. 
if notDefined('batchDir')
    batchDir = specifyBatchDir;
end

% Create a name for the batch .sh file. Write as the first line the code
% that specifies that it's a shell script. 
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
batchFileName = fullfile(ssDir,[projectName, '_', hem, '_ctrBatchGen_', dateAndTime, '.sh']);
fid = fopen(batchFileName, 'w');
fprintf(fid, '\n#!/bin/bash');
fprintf(fid, '\n# Log file used: %s \n', logFileName);

% Initialize counter
c = 0;

% Loop through all the subjects and for each one specify the full path to
% the .sh file for that subject.
for ii=1:length(subs)
    for jj=1:length(dtiYr)
        subDir = dir(fullfile(batchDir,dtiYr{jj},[subs{ii} '*']));
        subDir = fullfile(batchDir,dtiYr{jj},subDir.name);
        theSHfile = fullfile(subDir,dtDir,'fibers','conTrack',shName);
        ctrDir = mrvDirup(theSHfile);
        
        % If it exists, write the whole path to that person's .sh file. This
        % basically means that we will execute that person's .sh file.
        if exist(theSHfile)
            fprintf(fid,'\n\ncd %s',ctrDir); % Change to the conTrack dir before running the .sh.
c = (c+1); % counter

            % The & tells the script to go ahead and run the next line in parallel
            % with the line just executed, and we only want to do at most three
            % people at a time, to be polite to other users of teal, so we leave
            % off the & for every third person.
            if mod(c,3) ~= 0
                fprintf(fid, '\n%s', theSHfile);
            else
                fprintf(fid, '\n%s', theSHfile);
            end

            % If the file does not exist, we write a comment saying so.
        else
            fprintf(fid, '\n\n# File not found: %s', theSHfile);
        end
    end
end

fclose(fid); % Close out the log file

% Edit permissions of the .sh file (batchFileName) so that it can be executed.
[status,result] = system(['chmod 775 ' batchFileName]);
if status ~= 0
    disp(['chmod failure in ctr_FFA_batchConTrackGen.m line 89: Permissions need to be edited manually for ' batchFileName]);
end

% Display in the command window the command that can be copied and pasted
% in a terminal to run all of the .sh files.
fprintf('\n...\nCopy and paste the following line of code into your shell to execute all of the .sh files: \n. %s \n', batchFileName);

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function logFileName = specifyExistingLogfileToCopy

theChoice = '';
while ~ismember(theChoice,lower({'y','n'}))
    theChoice=input('Would you like to specify the log file? Y or N: ','s'); 
end

if theChoice == 'y'
    [f, p] = uigetfile({'*.txt';'*.*'}, 'Choose Log File...', '/biac3/wandell4/data/reading_longitude/dti_adults/OTS_Broca/logs');
    if(isnumeric(f))
        disp('Choose log file canceled.'); 
        return; 
    end
    defaultPath = p;
    logFileName = fullfile(p,f);
elseif theChoice == 'n'
    logFileName = 'None Specified'; 
end
return 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function shName = specifyShName

shName = 0;
while(isnumeric(shName))
    disp('You must choose a .sh file from an example subject.');
    [shName, p] = uigetfile({'*.sh';'*.*'}, 'Choose .sh File from example subject...','/biac3/wandell4/data/reading_longitude/dti_adults/rfd080930/dti40/fibers/conTrack'); 
end

return
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function batchDir = specifyBatchDir

batchDir = 0;
while(isnumeric(batchDir))
    disp('You must specify the directory to batch from.');
    [batchDir] = uigetdir(pwd, 'Choose batch directory...'); 
end

return    
