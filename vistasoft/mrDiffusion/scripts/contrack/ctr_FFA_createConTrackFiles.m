function ctr_FFA_createConTrackFiles(dt6s,allroiPairs, ctrParams)

% Usage: ctr_FFA_createConTrackFiles(dt6s,allroiPairs, ctrParams)
%
% This script loops through a list of subjects, creates a ctrSampler.txt
% and ctrScript.sh files. Using the same functions called by the ctrInit
% GUI, but without having to go through the GUI itself.
%
% The user should create 3 cell-arrays with full paths to the dt6, roi1 and
% roi2 files. Example:
% dt6s{ii} = '/biac3/kgs5/mri/071308_gg_dti/dti30/dt6.mat'
% roi1Files{ii} = '/biac3/kgs5/mri/071308_gg_dti/dti30/ROIs/rFFA.mat'
% roi2Files{ii} = '/biac3/kgs5/mri/071308_gg_dti/dti30/ROIs/rLO.mat'
%
% History:
% 2008.09.17 DY & MP
% 2008.09.22 MP added spName so that we can assign and pass on a unique
% name for the ctrSampler file.
% 2009.03.10 GS & DY: Added SCRIPTPATH field to ctrParams so user can
% specify where to save the ctrSampler & ctrScript files. For example,
% usage of this field see: ctr_FFA_nrsaamygdalapilot.m.  Also updated
% section of code that creates NOINFO ctrSampler & ctrScript files. 


% Check ctrParams for scriptPath field
if ~isfield(ctrParams, 'scriptPath')
    ctrParams.scriptPath = fullfile('fibers','conTrack');
end

%% Start a log text file to document successes and failures in preprocessing
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile('/biac2/kgs/projects/Kids/dti/amygdalaTracking','logs',['conTrackCtrScriptLog_NRSA_' dateAndTime '.txt']);
fid=fopen(logFile,'w');
startTime = clock;

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Creating ctrScripts for subjects in the dti directory\n\n');
% Print number of directories in age group to log
fprintf('\nFound %d suitable subjects in the dti directory\n\n',length(dt6s));
fprintf(fid,'\nFound %d suitable subjects in the dti directory\n',length(dt6s));

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'ctrInit Parameters:\n\n');
fprintf(fid,'\t Number of Samples: %d\n',ctrParams.nSamples);
fprintf(fid,'\t Max Nodes: %d\n',ctrParams.maxNodes);
fprintf(fid,'\t Min Nodes: %d\n',ctrParams.minNodes);
fprintf(fid,'\t Step Size: %d\n',ctrParams.stepSize);
fprintf(fid,'\t PDDPDF Flag (1=Always Compute): %d\n',ctrParams.pddpdfFlag);
fprintf(fid,'\t WM Flag (1=Always Compute): %d\n',ctrParams.wmFlag);
fprintf(fid,'\t ROI 1 Seed Flag (1=Seed ROI): %d\n',ctrParams.roi1SeedFlag);
fprintf(fid,'\t ROI 2 Seed Flag (1=Seed ROI): %d\n\n',ctrParams.roi2SeedFlag);
fprintf(fid,'\t Script Time Stamp: %d\n\n',ctrParams.timeStamp);
fprintf(fid,'\t Script Path: %s\n\n', ctrParams.scriptPath);
fprintf(fid,'\n ------------------------------------------ \n');



for ii=1:length(dt6s)
    
    params.dt6File      = dt6s{ii};
    params.dSamples     = ctrParams.nSamples;
    params.maxNodes     = ctrParams.maxNodes;
    params.minNodes     = ctrParams.minNodes;
    params.stepSize     = ctrParams.stepSize;
    params.pddpdf       = ctrParams.pddpdfFlag;
    params.wm           = ctrParams.wmFlag;
    params.roi1Seed     = ctrParams.roi1SeedFlag;
    params.roi2Seed     = ctrParams.roi2SeedFlag;
    params.timeStamp    = ctrParams.timeStamp; % See subFunction below

    % Fields printed to log file
    subCode = mrvDirup(dt6s{ii},2);
    [tmp subCode] = fileparts(subCode);
    fprintf('\nProcessing %s... \n',subCode);
    fprintf(fid,'\nProcessing %s... \n',subCode);
    fprintf(fid,'\t dt6 File: %s\n',dt6s{ii});

    % For this subject loop over all ROI pairs.
    for jj=1:length(allroiPairs{ii});

        params.roi1File = allroiPairs{ii}(jj).roi1;
        params.roi2File = allroiPairs{ii}(jj).roi2;

        fprintf(fid,'\t ROI pair: %d\n',jj);
        fprintf(fid,'\t\t ROI 1: %s\n',allroiPairs{ii}(jj).roi1);
        fprintf(fid,'\t\t ROI 2: %s\n',allroiPairs{ii}(jj).roi2);

        % This does ALMOST EVERYTHING
        % 1. Creates wmprob.nii.gz
        % 2. Creates pdf.nii.gz
        % 3. Create ROI mask.nii.gz
        % 4. Create the ctrSampler_timestamp.txt file
        % 5. Create the ctrScript_timestamp.sh file
        samplerName = ['ctrSampler_',allroiPairs{ii}(jj).fname,'_',params.timeStamp,'.txt'];
        samplerName = fullfile(mrvDirup(dt6s{ii},2),ctrParams.scriptPath,samplerName);
        params = ctrInitParamsFile(params,samplerName);
        fprintf(fid,'\t ctr.txt: %s\n',samplerName);
        bashName = ['ctrScript_',allroiPairs{ii}(jj).fname,'_',params.timeStamp,'.sh'];
        bashName = fullfile(mrvDirup(dt6s{ii},2),ctrParams.scriptPath,bashName);
        ctrScript(params,bashName,'pdb');
        fprintf(fid,'\t ctr.sh: %s\n',bashName);

        % Now we make versions of the ctrSampler_timestamp.txt and
        % ctrScript_timestamp.sh file that are adjusted to track fibers
        % while ignoring the diffusion data (treating all tensors as
        % spheres).
        if(exist(samplerName) && exist(bashName))
            [tmp,oldctrSamplerFile]=fileparts(samplerName);
            newctrSamplerFile=makeNoDataContrackSampler(samplerName,allroiPairs{ii}(jj).fname,params.timeStamp);
            newctrScriptFile=makeNoDataContrackScript(bashName,allroiPairs{ii}(jj).fname,params.timeStamp,newctrSamplerFile,oldctrSamplerFile);
            fprintf(fid,'\tSuccessfully created %s\n',newctrSamplerFile);
            fprintf(fid,'\tSuccessfully created %s\n',newctrScriptFile);
        else
            fprintf(fid,'\tCould not create %s, problem with sampler/bash files\n',newctrSamplerFile);
            fprintf(fid,'\tCould not create %s, problem with sampler/bash files\n',newctrScriptFile);
        end

    end

end

return
        
%%

totalTime=etime(clock,startTime);

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);

fprintf('\n Script Completed in a total time of %f minutes\n',totalTime/60);

% % Write script used into the log
% newfid=fopen(which('ctr_FFA_createConTrackFiles.m'), 'r');
% code = fread(newfid); fclose(newfid);
% code = char(code)';
% fprintf(fid, '\n\n-----------------------\n%s', code);
% fclose(newfid); 

fclose(fid); % Close out the log file

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

function newctrSamplerFile=makeNoDataContrackSampler(samplerName,fname,timeStamp)

% This function will take the existing ctrSampler.txt file just generated,
% and make a new ctrSampler_nodata.txt file by modifying these lines, which
% will result in contrack_gen ignoring the existing tensor data (treat all
% tensors as spheres):
%
% Local Path Segment Smoothness Standard Deviation: 59
% ShapeFunc Params (LinMidCl,LinWidthCl,UniformS): [ 0.99, 0.01, 100 ]
%
% SAMPLERNAME: must be full path and file name for ctrSampler.txt file
% NOTE: requires the lines above to be a particular location in the text
% file!
%
% Will output newctrSamplerFile: file name only of new ctrSampler.txt file

samplerFid = fopen(samplerName, 'r');
samplerText=textscan(samplerFid,'%s',18,'delimiter','\n');

% First fix the 4th line: PDF Filename: pdf.nii.gz becomes pdfNoInfo.nii.gz
colon = strfind(samplerText{1}(4), ':');
line = strtok(samplerText{1}(4), ':');
line{1}(colon{1}:colon{1}+17) = ': pdfNoInfo.nii.gz';
samplerText{1}(4) = line;

% Open a new .txt file and write all text to the file. 
newctrSamplerFile = ['ctrSampler' fname '_noInfo_' timeStamp];
fid = fopen(fullfile(mrvdirup(samplerName), [newctrSamplerFile '.txt']), 'w');
for jj=1:length(samplerText{1})
    writeThisLine = samplerText{1}(jj);
    fprintf(fid, writeThisLine{1});
    fprintf(fid, '\n');
end
fclose(fid);

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newctrScriptFile=makeNoDataContrackScript(bashName,fname,timeStamp,newctrSamplerFile,oldctrSamplerFile)

% This function will take the existing ctrScript.sh file just generated,
% and make a new ctrScript_SFN_nodata.sh file that will call the
% ctrSampler_SFN_nodata.txt just generated.
%
% Needs lots of input arguments to be just right (bashName = full path to
% bash script file; newctrSamplerFile = full path to new ctrSampler file;
% oldctrSamplerFile = file name only of old ctrSampler.txt file
%
% Will output NEWCTRSCRIPTFILE: file name only of new ctrScript.sh file

bashFid = fopen(bashName, 'r');
bashText=textscan(bashFid,'%s', 4,'delimiter','\n');

% Use STRREP to replace the line calling the old ctrSampler.txt file with
% the new ctrSampler_SFN_nodata.txt file
line = bashText{1}(2);
line = strrep(line, oldctrSamplerFile, newctrSamplerFile);
bashText{1}(2) = line;

% Save it out into a new file
newctrScriptFile = ['ctrScript' fname '_noInfo_' timeStamp '.sh'];
fid = fopen(fullfile(mrvdirup(bashName), newctrScriptFile), 'w');
for kk=1:length(bashText{1})
    writeThisLine = bashText{1}(kk);
    fprintf(fid, writeThisLine{1});
    fprintf(fid, '\n');
end
fclose(fid);

return
