function ctr_conTrackBatchScore(infoFile,numPathsToScore,multiThread)
 
%ctr_batchConTrackScore([infoFile = uigetfile],[numPathsToScore = '1000'])
%
% This function will allow the user to score multiple conTrack fiber sets
% across subjects. The user must point to a infoFile that was created with
% ctr_makeConTrackFiles.m That script will place all relevant data into a
% struct which this function will read in. 
%
% If multiThread == 1 all scoring commands will be executed in parallel.
%
% We save out the top numpathstoscore from the original fiber group. This
% is the --thresh and --sort option in contrack_score.glxa64. See
% http://white.stanford.edu/newlm/index.php/ConTrack#Score_paths for more
% info. 
%
% 2009.08.31 LMP Wrote The Thing
% 2009.09.20 LMP added a line that will ask how many fibers you would like
% to score out of x.


%% Load the .MAT file created by ctr_makeConTrackFiles

if notDefined('infoFile')
[f, p] = uigetfile({'*.mat';'*.*'}, 'Choose Log .mat File...', pwd);
        infoFile = fullfile(p,f);
end

    load(infoFile);
    projectName = info.projectName;
    batchDir = info.baseDir;
    dtiYr = info.dtiYr;
    subs = info.subs;
    dtDir = info.dtDir;
    ROI1 = info.roi1;    
    ROI2 = info.roi2;
    logDir = info.logDir;
    scrDir = info.scrDir;
    timeStamp = info.timeStamp;
    nSamples = info.nSamples; 
    nSamples = num2str(nSamples);

    cd(batchDir);

    % Build up the struct with the ROI pairs. We need the names of these ROI
    % pairs to sort the .sh scripts later on. 
    roiPair = {};

    for ff=1:length(ROI1)
        if numel(ROI2) == 1
            fname = [ROI1{ff}, '_', ROI2{:}];
        else
            fname = [ROI1{ff}, '_', ROI2{ff}];
        end
        roiPair{ff} = fname;
    end

%% Set-up other Input Variables

if notDefined('numPathsToScore')
    numPathsToScore = input(['Please enter the number of paths you would like scored [out of ' nSamples ']: '],'s');
end

if isempty(numPathsToScore), error('Number of paths to score not valid'); end

if notDefined('multiThread')
    multiThread = input('Would you like to use multiple cores? \n Enter 0 (No) or 1 (Yes): ');
end

if isempty(numPathsToScore), error('Number of paths to score not valid'); end

fileType = '.pdb';

%%  Create a name for the batch .sh file.

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
batchFileName = fullfile(scrDir,[projectName,'_ctrBatchScore_',dateAndTime,'.sh']);

    fid = fopen(batchFileName, 'w');
    fprintf(fid, '\n#!/bin/bash');
    fprintf(fid, '\n# Log file used: %s \n',infoFile);

    % Build/set arguments for contrack_score.glxa64 command.
    ctrScore = 'contrack_score.glxa64';
    thresh = [' --thresh ', numPathsToScore, ' --sort '];

%% Start mass loop here

for ii=1:length(subs)
    for jj=1:length(dtiYr)
        sub = dir(fullfile(batchDir,dtiYr{jj},[subs{ii} '*']));
        subDir = fullfile(batchDir,dtiYr{jj},sub.name);
        fiberDir = fullfile(subDir,dtDir,'fibers','conTrack');

       % For each roiPair find the associated .sh file. There are many .sh files (potentially)
        for kk=1:numel(roiPair)
            fgOutName = ['scoredFG_',projectName,'_',roiPair{kk},'_top',numPathsToScore];
            fgout = [fgOutName, fileType]; 
            cd(fiberDir);
            theSHfile = dir(['*',roiPair{kk},'*',timeStamp,'.sh']);
            theSHfile = theSHfile.name; 
                fid2 = fopen(theSHfile);
                tmp = fgetl(fid2);
                line = fgetl(fid2);
                [ctrSampler, fginName] = getInfoFromShFile(line);
                fclose(fid2);
                theCD = ['cd ' fiberDir];
                fprintf(fid, '\n%s', theCD);
                theCmd = [ctrScore, ' -i ', ctrSampler, ' -p ', fgout, thresh, fginName];
                if multiThread == 1
                    fprintf(fid, '\n%s &\n', theCmd);
                else
                    fprintf(fid, '\n%s\n', theCmd);
                end
                    
        end
    end
end

fclose(fid); 

% Edit permissions of the .sh file (batchFileName) so that it can be executed.
[status,result] = system(['chmod 775 ' batchFileName]);
if status ~= 0
    disp(['chmod failure in ctr_FFA_batchConTrackScore.m line 57: Permissions need to be edited manually for ' batchFileName]);
end

% Display in the command window the command that can be copied and pasted
% in a terminal to run all of the .sh files.
cd(scrDir);
fprintf('Copy and paste the following line of code into your shell to batch score: \n. %s \n ',batchFileName);

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

















    