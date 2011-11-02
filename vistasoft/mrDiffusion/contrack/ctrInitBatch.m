function [cmd infoFile] = ctrInitBatch(ctrParams)
%  function [cmd infoFile] = ctrInitBatch(ctrParams)
% 
% OVERVIEW
%       This script takes functions from ctrInit and makes the sampler.txt
%       and .sh files (used by conTrack to generate fibers) for a large
%       group of subjects using as many pairs of ROIs as the user desires. 
% 
%       The logFile: Reports the results of the process as well as the
%       parameters used to setup the tracking script.
%  
%       The infoFile: (info structure) Created for use with
%       ctr_conTrackBatchScore.m and saved in the log dir with the same
%       name as the log file.
%  
%       What you end up with here is: (1) log file (2) log.mat file (for
%       use with ctr_conTrackBatchScore (path = infoFile), and (3) .sh
%       shell script that will be displayed in the command window, which
%       will run tracking for all subjects and ROIs specified. The
%       resulting .sh file (3) should be run on a 64-bit linux machine with
%       plenty of power. 
% 
% USAGE NOTES:
%       The user should use ctrInitBatchParams to initialize the structure
%       that will contain all variables and algorithm params. see
%       ctrInitBatchParams.m - mrvBrowseSVN('ctrInitBatchParams');
% 
%       After the script has completed the user will see instrucitons
%       appear in the command window telling the user to copy and paste a
%       provided line of code into their terminal in order to initiate
%       tracking. They will also see the full path to the log file that was
%       created by this script. 
% 
%       The directory in which the fibers will be saved is: subDir/fibers/conTrack/
% 
% INPUTS: 
%       ctrParams - a structure containing all variables needed to run this
%                   code. Get this struct by running 'ctrInitBatchParams'
% 
% OUTPUTS:
%       cmd   - the command that can be run from your terminal to initiate
%               tracking. ** Why don't we allow the user to execute the
%               command through matlab??? Becuase it takes up matlab
%               licenses for the duration of the tracking - which is not
%               good.
%       info  - a structure containing all the parameters used for
%               tracking. info can be passed in to ctrBatchScore to
%               initiate scoring. 
% 
% VARIABLES:  ** See ctrInitBatchParams to create these variables **
%       projectName = This variable will be used in the name of all the files 
%                     that are created. E.g., 
%                     outFile = ['fg_',projectName,'_',roi1,'_',roi2,'_',timeStamp,'.pdb'];                       
%       logName     = This will be used to provide a unique name for easy ID in the log directory.                           
%       baseDir     = Top-level directory containing your data. 
%                     The level below baseDir should have each subjects data directory.                           
%       dtDir       = This should be the name of the directory containing 
%                     the dt6.mat file. E.g., dti40trilinrt.                          
%       logDir      = This directory will contain the log files for this project.                        
%       scrDir      = This directory will contain the .sh files used for tracking in linux.
%       subs        = This is the cell array that will contain the names 
%                     of all the sujbect's directories that will be
%                     processed. ( e.g. subs = {'sub1','sub2','sub3'}; )
%                     NOTE: This script also supports the ability to load a
%                     list of subjects from a text file. If you wish to do
%                     this simply comment out the subs variable in section
%                     I or leave the cell empty. You will be prompted to
%                     select a text file that contains a list of subjects.
%                     Please assure that this list is a simple text file
%                     with only subject names seperated by new lines or
%                     spaces.  
%       ROI1 & ROI2 = These two cell arrays should contain the names of
%                     each ROI to be used in tracking. The script will
%                     track from ROI1{1} to ROI2{1} and ROI1{2} to ROI2{2}
%                     etc... Use .mat files, but DO NOT include file
%                     extensions. In case that you wish to track from
%                     multiple rois (ROI1) to the same roi (ROI2) you can
%                     just place the name of one roi in ROI2 and each roi
%                     in ROI1 will be tracked to the single roi in ROI2.
%                     E.g., ROI1 = {'Roi1a','Roi1b'}; ROI2 =
%                     {'Roi2a','Roi2b'};
% 
% EXAMPLE USUAGE:
%       ctrParams          = ctrInitBatchParams;
%       ctrParams.baseDir  = '/Directory/Containing/Data';
%       ctrParams.dtDir    = 'dti40trilin';
%       ctrParams.subs     = {'subDir1','subDir2'};
%       ctrParams.ROI1     = {'Roi1a','Roi1b'};
%       ctrParams.ROI2     = {'Roi2a','Roi2b'};
%       ctrParams.nSamples = 10000;
%       [cmd info] = ctrInitBatch(ctrParams);
% 
% WEB RESOURCES:
%       http://white.stanford.edu/newlm/index.php/ConTrack
%       mrvBrowseSVN('ctrInitBatch');
%       
% HISTORY: 
%       08.27.2009: LMP Wrote the thing
%       07.23.2010: LMP adapted from ctr_makeConTrackFiles to make the code more
%                   general.
%       08.16.2011  LMP adapted the code from ctrBatchCreateContrackFiles.m 
%                   and fundamentally changed the code - now it gets
%                   ctrParams from ctrInitBatchParams. This code now does
%                   not need to be edited by the user. One day I'll rewrite
%                   the whole thing - it could be better...
% 
% (C) Stanford Vista, 8/2011 [lmp]
% 
% 
%% A. Check for params. If any of the key params are missing - error
%
if notDefined('ctrParams') ...
        || isempty(ctrParams.baseDir) ...
        || isempty(ctrParams.dtDir) ...
        || isempty(ctrParams.roiDir) ...
        || isempty(ctrParams.ROI1)
    doc('ctrInitBatchParams')
    error('You must run ctrInitBarchParams to initialize the required variables');
end

%% I. Set Naming and Directory Structure 
% 
projectName = ctrParams.projectName;                                        
logName     = ctrParams.logName;      
baseDir     = ctrParams.baseDir;                      
dtDir       = ctrParams.dtDir;
roiDir      = ctrParams.roiDir;
                            

%% II. Set Subjects and ROIs
% 
subs = ctrParams.subs; 
    % If subs is empty then we ask for a text file contining a list of
    % subjects. 
if isempty(subs) || numel(subs) == 0 
    [subFile filePath] = uigetfile('*.txt','Select text file containing a list of subjects.');
    subFile            = [filePath subFile];
    subs               = textread(subFile,'%s');
    % If the subs variable contans the path to a file containing sub names
    % we read it in here.
elseif exist('subs','file')
    subs = textread(subs,'%s');
end

ROI1 = ctrParams.roi1;    
ROI2 = ctrParams.roi2;
  

%% III. Set Parameters
% 
nSamples     = ctrParams.nSamples;    
maxNodes     = ctrParams.maxNodes;    
minNodes     = ctrParams.minNodes;    
stepSize     = ctrParams.stepSize;        
pddpdfFlag   = ctrParams.pddpdfFlag;      
wmFlag       = ctrParams.wmFlag;        
roi1SeedFlag = ctrParams.roi1SeedFlag;  
roi2SeedFlag = ctrParams.roi2SeedFlag;  
multiThread  = ctrParams.multiThread;   


%% %%%%%%%%%%%%%%%%% Don't Edit Below %%%%%%%%%%%%%%%%%%%%%%%
% 
    % Create log directory and scripts directory
logDir = fullfile(baseDir,'ConTrack', projectName,'logs');
scrDir = fullfile(baseDir,'ConTrack', projectName,'shellScripts');

%% IV. Create log and batchScript files 
% 
    % Set the time once for the whole script
timeStamp = datestr(now,30);    
timeStamp(strfind(timeStamp,'T')) = '_';
timeStamp = [timeStamp(1:4) '-' timeStamp(5:6) '-' timeStamp(7:11) '.' ...
             timeStamp(12:13) '.' timeStamp(14:15)];

dateAndTime = getDateAndTime;

if ~exist(logDir,'file'), mkdir(logDir); disp('Created Log Directory'); end
if ~exist(scrDir,'file'), mkdir(scrDir); disp('Created Shell Script Directory'); end

logFileName = fullfile(logDir,[projectName,'_',logName, '_ctrLog_', dateAndTime]);
logFile     = [logFileName, '.txt'];
fid         = fopen(logFile,'w');


%% V. Start writing the batch File that will run all resulting .sh files
% 
batchFileName = fullfile(scrDir,[logName, '_ctrGenBatch_', dateAndTime '.sh']);
fid2 = fopen(batchFileName, 'w');
fprintf(fid2, '\n#!/bin/bash');
fprintf(fid2, '\n# Log file used: %s \n', logFile);


%% VII. Create info file that will be loaded for scoring - same name as log file
% 
    info             = struct;
    info.projectName = projectName;
    info.baseDir     = baseDir;
    info.subs        = subs;
    info.dtDir       = dtDir;
    info.roi1        = ROI1;
    info.roi2        = ROI2;
    info.logDir      = logDir;
    info.scrDir      = scrDir;
    info.timeStamp   = timeStamp;
    info.nSamples    = nSamples;
    infoFile         = [logFileName,'.mat'];
    save(infoFile,'info');
    
    
%% VIII. Log/Info Files: Print params to log and info files
%     
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

    
%% IX. Create the ctrSampler and .sh files
%     
    for ii=1:numel(subs)
        fprintf(fid,'\n ------------------------------------------ \n');
        fprintf(fid2,'\n');

        sub = dir(fullfile(baseDir,[subs{ii} '*']));
        if ~isempty(sub) 
            subDir = fullfile(baseDir,sub.name);
            dt6Dir = fullfile(subDir,dtDir);
            dt6 = fullfile(dt6Dir,'dt6.mat'); 

            rDir = fullfile(subDir,roiDir);

            fiberDir = fullfile(dt6Dir,'fibers','conTrack');
            if ~exist(fiberDir,'file'), mkdir(fiberDir); disp('Created conTrack dir...'); end

            for kk=1:numel(ROI1)
                roi1 = fullfile(rDir, [ROI1{kk},'.mat']);
                if numel(ROI2) == 1
                    roi2 = fullfile(rDir, [ROI2{:},'.mat']); 
                    fname = [ROI1{kk}, '_', ROI2{:}];
                else
                    roi2 = fullfile(rDir, [ROI2{kk},'.mat']);
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

                [~,roi1] = fileparts(params.roi1File);
                [~,roi2] = fileparts(params.roi2File);

                % Set the name for the superSet of fibers.
                outFile = ['fg_',projectName,'_',roi1,'_',roi2,'_',timeStamp,'.pdb'];

                % Creates the .sh file
                ctrScript(params,bashName,outFile);

                fprintf(fid,'\t ctr.sh: %s\n',bashName);

                % Writes the command to the batchShFilebatchFileName
                % Change to the conTrack dir before running the .sh.
                fprintf(fid2,'\n\ncd %s',fiberDir); 

                if multiThread == 1
                    fprintf(fid2, '\n%s &', bashName);
                else
                    fprintf(fid2, '\n%s', bashName);
                end
            end
        else
            fprintf(['\n No data for ' subs{ii} '! Skipping. \n']);
            fprintf(fid,'\n No data for %s. Skipping!\n', subs{ii});
        end
    end

    
%% X. Close things out
% 
fprintf(fid,'\n ------------------------------------------ \n');

fprintf('\n Script Completed.');

fclose(fid);  % Close out the log file
fclose(fid2); % Close out the log file

    % Edit permissions of the .sh file (batchFileName) so that it can be executed.
[status,~] = system(['chmod 775 ' batchFileName]);
    if status ~= 0
        disp(['chmod failure. Permissions need to be edited manually for ' batchFileName]);
    end

    % Display in the command window the command that can be copied and pasted
    % in a terminal to run all of the .sh files.
cd(scrDir);
fprintf('\n...\nLog file created: \n %s \n', logFileName);
fprintf('\n...\nRun the following line of code in your terminal: \n. %s \n', batchFileName);
cmd = batchFileName;

return
