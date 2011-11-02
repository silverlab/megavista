% dti_FFA_preprocessScript_realign
%
% Usage: dti_FFA_preprocessScript_realign
%
% By: DY 2008/05/09
%
% This script will take a predefined list of subjects, delete their
% acpcxform files, and recompute dtiRawPreprocess with clobber set to false
% (so that eddies are not recomputed). This will create a new dt6 file.
% Errors and progress are logged to a text file. 

% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\';
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/';
end

subjects = {fullfile('adults','dy_25yo_041408_FreqDirLR')};

% Files
dtiNifti=fullfile('raw','dti_g865_b900.nii.gz');
t1=fullfile('t1','t1.nii.gz');
bval=.9;
gradfilecode=865;

% Start a log text file to document successes and failures in preprocessing
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(dtiDir,['PreprocessingRealignLog_' dateAndTime '.txt']);
fid=fopen(logFile,'w');
startTime = clock;

% Loops through each of the age directories
for ii=1:length(subjects)
    thisDir = fullfile(dtiDir,subjects{ii}); cd(thisDir);
    fprintf(fid,'\n ------------------------------------------ \n');
    
    % Check frequency encode direction, and set freqdirAPflag to 1 if
    % frequency encode direction is A/P (phase = L/R)
    if exist(fullfile(thisDir,'raw','dti_g865_b900','I0001.dcm'))
        info = dicominfo(fullfile(thisDir,'raw','dti_g865_b900','I0001.dcm'));
        % If phase encode direction is L/R and frequency encode
        % direction is A/P (two are orthogonal), info field will return
        % ROW and a special flag should be set in dtiRawPreprocess
        if strcmp(info.InPlanePhaseEncodingDirection,'ROW')
            freqdirAPflag=1;
        else
            freqdirAPflag=0;
        end
        dicomsOK = true;
        fprintf(fid,'AP flag is %d for %s \n\n',freqdirAPflag,subjects{ii});
        fprintf('AP flag is %d for %s \n\n',freqdirAPflag,subjects{ii});
    else
        dicomsOK = false;
        fprintf(fid,'AP flag not found for %s \n\n',subjects{ii});
        fprintf('AP flag not found for %s \n\n',subjects{ii});
    end
    
    % Delete acpc xform file, so that this can be recomputed with new t1
    % nifti
    if exist(fullfile(thisDir,'raw','dti_g865_b900_acpcXform.mat'));
        delete(fullfile(thisDir,'raw','dti_g865_b900_acpcXform.mat'));
        fprintf(fid,'Deleted acpcxform for %s \n\n',subjects{ii});
        fprintf('Deleted acpcxform for %s \n\n',subjects{ii});
        preprocessOK = dicomsOK; % sets this to TRUE if dicomsOK was also TRUE
    else
        fprintf(fid,'ERROR: could not find acpcxform for %s \n\n',subjects{ii});
        fprintf('ERROR: could not find acpcxform for %s \n\n',subjects{ii});
        preprocessOK = false;
    end

    %------------------------------------------------
    % THIS ACTUALLY DOES THE PREPROCESSING
    %------------------------------------------------
    
    if preprocessOK % Only proceed if true (APflag extracted, acpcxform deleted
        [junk,subCode] = fileparts(thisDir);
        fprintf('Processing %s... \n',subCode);
        fprintf(fid,'Processing %s... \n',subCode);
        fprintf(fid,'\t Nifti: %s\n',dtiNifti);
        fprintf(fid,'\t T1: %s\n',t1);
        fprintf(fid,'\t Bval: %.03f\n',bval);
        fprintf(fid,'\t GradFileCode: %d\n',gradfilecode);
        fprintf(fid,'\t FreqDir AP?: %d\n',freqdirAPflag);
        try
            tic
            dtiRawPreprocess(dtiNifti, t1, bval, gradfilecode, false,[], freqdirAPflag);
            time=toc;
            fprintf(fid,'Preprocessed %s successfully in %f seconds \n',subCode,time);
            fprintf('Preprocessed %s successfully in %f seconds \n',subCode,time);
        catch
            fprintf(fid,'FAILURE: %s at dtiRawPreprocess \n',subCode);
            fprintf('FAILURE: %s at dtiRawPreprocess \n',subCode);
        end

        % Clip negative eigenvalues to 0 for tensor files
        try
            dt6file=fullfile(thisDir,'dti30','dt6.mat');
            tensorfile=fullfile(thisDir,'dti30','bin','tensors.nii.gz');
            dtiFixTensorsAndDT6(dt6file,tensorfile);
            fprintf(fid,'Tensors clipped for %s \n',subCode);
            fprintf('Tensors clipped for %s \n',subCode);
        catch
            fprintf(fid,'FAILURE TO CLIP TENSORS for %s\n',subCode);
            fprintf('FAILURE TO CLIP TENSORS for %s\n',subCode);
        end

    end
end

totalTime=etime(clock,startTime);

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);
fprintf('Total running time for script: %f minutes \n',totalTime/60);

fclose(fid); % close out the log file