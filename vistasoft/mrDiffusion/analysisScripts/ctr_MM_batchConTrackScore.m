function ctr_MM_batchConTrackScore(shName, fgoutName, numPathsToScore)
% ctr_MT_batchConTrackScore([shName = uigetfile], [fgoutName =
% 'scoredFG'], [numPathsToScore = '1000'])
%
% This will loop through a list of subjects find the specified .sh file
% (this should be EXACTLY the same name) for each subject and read in the
% ctrSampler.txt and .Bfloat file names created during the initial conTrack
% generation stage. It will create a new batch .sh file that will score
% each fiber group as the user specifies. 
%
% We save out the top numpathstoscore from the original fiber group. This
% is the --thresh and --sort option in contrack_score.glxa64. See
% http://white.stanford.edu/newlm/index.php/ConTrack#Score_paths for more
% info. 
%
% 2008.12 DY & MP
% 2008.12.15 MP Modified to work for DTI longitudinal data


%% Set Subjects and Directories
% Add a project name to the .sh file for easy id.
projectName = 'Controls_Mori_Occ_CC_100k';
%  hem = 'LEFT';
 hem = 'RIGHT';
% hem = '';

numPathsToScore = '20000';
fileType = '.pdb';

% Set batch directory and change to that directory for easy navigation.
batchDir = '/biac3/wandell4/data/reading_longitude/';
logDir = fullfile(batchDir, 'dti_adults','ctr_controls','shellScripts');
dtiYr = {'dti_adults'};
% subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311',...         
%     'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
%     'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};
% 
% % subs = {'dl070825','am090121'};
% % subs = {'mm_temp040325'};
% % subs = {'aab050307','aw040809','bw040922', 'gd040901','jm061209'...
% %     'me050126','rfd040630','sd050527','sn040831','mm_temp040325'};mbs040503

subs = {'bw040922'};

cd(batchDir);


%% 

% Specify batchDir, which is the directory that should contain a list of
% all the subjects directories to process. 
if notDefined('batchDir') %%%%%%%% This should be set for each loop. 
    batchDir = specifyBatchDir;
end

if notDefined('numPathsToScore')
    numPathsToScore = '1000';
end

if notDefined('fgoutName')
    fgoutName = ['scoredFG_',projectName,'_top',numPathsToScore,'_',hem];
end

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

% Create a name for the batch .sh file. Write as the first line the code
% that specifies that it's a shell script. 
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
batchFileName = fullfile(logDir,[projectName,'_', hem, '_ctrBatchScore_',dateAndTime,'.sh']);
fid = fopen(batchFileName, 'w');
fprintf(fid, '\n#!/bin/bash');
fprintf(fid, '\n# Log file used: %s \n',logFileName)
% Build/set arguments for contrack_score.glxa64 command.
ctrScore = 'contrack_score.glxa64';
fgout = [fgoutName, fileType]; 
thresh = [' --thresh ', numPathsToScore, ' --sort '];

%%% Start mass loop here
for ii=1:length(subs)
    for jj=1:length(dtiYr)
        %subDir = dir(fullfile(batchDir,dtiYr{jj},subs{ii}));
        subDir = fullfile(batchDir,dtiYr{jj},subs{ii});
        theSHfile = fullfile(subDir,'dti06','fibers','conTrack',shName);

        % If it exists, write the whole path to that person's .sh file. This
        % basically means that we will execute that person's .sh file.
        if exist(theSHfile)
            fid2 = fopen(theSHfile);
            tmp = fgetl(fid2);
            line = fgetl(fid2);
            [ctrSampler, fginName] = getInfoFromShFile(line);
            fclose(fid2);
            theCD = ['cd ' mrvDirup(theSHfile)];
            fprintf(fid, '\n%s', theCD);
            theCmd = [ctrScore, ' -i ', ctrSampler, ' -p ', fgout, thresh, fginName];
            fprintf(fid, '\n%s\n', theCmd);
        else
            fprintf(fid, '\n# File not found: %s', theSHfile);
        end
    end
end

fclose(fid); % Close out the log file

% Edit permissions of the .sh file (batchFileName) so that it can be executed.
[status,result] = system(['chmod 775 ' batchFileName]);
if status ~= 0
    disp(['chmod failure in ctr_FFA_batchConTrackScore.m line 57: Permissions need to be edited manually for ' batchFileName]);
end

% Display in the command window the command that can be copied and pasted
% in a terminal to run all of the .sh files.
cd(batchDir);
fprintf('Copy and paste the following line of code into your shell to batch score: \n. %s \n ',batchFileName);

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function batchDir = specifyBatchDir

batchDir = 0;
while(isnumeric(batchDir))
    disp('You must specify the directory to batch from.');
    [batchDir] = uigetdir(pwd, 'Choose batch directory...'); 
end

return    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function logFileName = specifyExistingLogfileToCopy

theChoice = '';
while ~ismember(theChoice,lower({'y','n'}))
    theChoice=input('Would you like to specify the log file? Y or N: ','s'); 
end

if theChoice == 'y'
    [f, p] = uigetfile({'*.txt';'*.*'}, 'Choose Log File...', '/biac3/wandell4/data/reading_longitude/dti_adults/ctr_controls/logs');
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
    [shName, p] = uigetfile({'*.sh';'*.*'}, 'Choose .sh File from example subject...','/biac3/wandell4/data/reading_longitude/dti_adults/bw040922/dti06/fibers/conTrack'); 
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ctrSampler, fginName] = getInfoFromShFile(line)
spaces = strfind(line,' ');
c = 1; % Counter
allWords = {};
for jj=1:length(spaces)
    theWord = line(c:spaces(jj));
    allWords{jj} = theWord;
    c = spaces(jj)+1;
end

theTxt = strmatch('-i', allWords)+1;
theFg = strmatch('-p', allWords)+1;
ctrSampler = allWords{theTxt};
fginName = allWords{theFg}(1:end-2); % leave off the ' mark and space.

return


    