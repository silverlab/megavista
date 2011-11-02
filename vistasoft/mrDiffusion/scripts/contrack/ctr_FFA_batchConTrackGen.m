function ctr_FFA_batchConTrackGen(logFileName, shName, batchDir)
% Usage: ctr_FFA_batchConTrackGen([logFileName], [shName], [batchDir])
%
% This script loops through a list of subjects and creates a .sh file that
% will run their ctrScript.sh files. It assumes that all subjects will
% have the exact same .sh file name. If logFileName and/or shName are not
% specified a GUI will open that will allow you to browse for them. 
%
% This script will output to the screen the full path and file name for the
% .sh file that will run all of the ctrScripts. 
% 
% 2008.12.1 DY & MP

% Allow user to specify the log file (or not) that contains parameters to
% be used by conTrackGen. These are typically specified in
% ctr_FFA_createConTrackFiles.  
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

% Go to the batch directory and create a cell array (subs) with all of the
% subjects to process in that directory. 
cd(batchDir);
s = dir('*0*');  subs={s.name};

% Create a name for the batch .sh file. Write as the first line the code
% that specifies that it's a shell script. 
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
batchFileName = fullfile(batchDir,['conTrackGenShBatch_' dateAndTime '.sh']);
fid = fopen(batchFileName, 'w');
fprintf(fid, '\n#!/bin/bash');
fprintf(fid, '\n# Log file used: %s \n',logFileName);

% Initialize counter
c = 0;

% Loop through all the subjects and for each one specify the full path to
% the .sh file for that subject. 
for ii=1:length(subs)
    subDir = fullfile(batchDir,subs{ii});
    theSHfile = fullfile(subDir,'fibers','conTrack',shName);
    ctrDir = mrvDirup(theSHfile);
    fprintf(fid,'\n\ncd %s',ctrDir);
    
    % If it exists, write the whole path to that person's .sh file. This
    % basically means that we will execute that person's .sh file.
    if exist(theSHfile)
        c = (c+1);
        
        % The & tells the script to go ahead and run the next line in parallel
        % with the line just executed, and we only want to do at most three
        % people at a time, to be polite to other users of teal, so we leave
        % off the & for every third person.
        if mod(c,3) ~= 0
            fprintf(fid, '\n%s &', theSHfile);
        else
            fprintf(fid, '\n%s', theSHfile);
        end
        
    % If the file does not exist, we write a comment saying so.
    else
        fprintf(fid, '\n# File not found: %s', theSHfile);
    end
end

fclose(fid); % Close out the log file

% Edit permissions of the .sh file (batchFileName) so that it can be executed.
[status,result] = system(['chmod 775 ' batchFileName]);
if status ~= 0
    disp(['chmod failure in ctr_FFA_batchConTrackGen.m line 82: Permissions need to be edited manually for ' batchFileName]);
end

% Display in the command window the command that can be copied and pasted
% in a terminal to run all of the .sh files.
fprintf('Copy and paste the following line of code into your shell to execute all of the .sh files: \n%s \n', batchFileName);

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function logFileName = specifyExistingLogfileToCopy

theChoice = '';
while ~ismember(theChoice,lower({'y','n'}))
    theChoice=input('Would you like to specify the log file? Y or N: ','s'); 
end

if theChoice == 'y'
    [f, p] = uigetfile({'*.txt';'*.*'}, 'Choose Log File...');
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
    [shName, p] = uigetfile({'*.sh';'*.*'}, 'Choose .sh File from example subject...'); 
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
