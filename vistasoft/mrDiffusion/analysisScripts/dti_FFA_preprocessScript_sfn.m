% dti_FFA_preprocessScript
%
% Usage: dti_FFA_preprocessScript
%
% By: DY 2008/02/24
% Modified: DY 2008/03/14: will also call dtiFixTensors to clip negative
% eigenvalues to 0. 
% Modified: DY 2008/06/17: deal with new directory structure, no age
% directories, new subs format
% Modified: DY 2008/10/31: only goes through SFN directory, will
% appropriately "reprocess" subjects who have already been preprocessed
% once
%
% This script will go through the Kids project DTI directory, and look for
% subjects suitable for preprocessing. Errors and progress are logged to a
% text file. 
%
% IMPORTANT: first make sure that directory is set up properly. 
% (1): dti (directory at top level of subDir with 7800 dicoms inside)
% (2): t1/t1.nii.gz
%
% HALLOWEEN STATUS: make subject dirs like ACG, then continue modifying
% this script until after checkForDicoms

% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\sfn\';
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/sfn/';
end
cd(dtiDir); s = dir('*0*');  subs={s.name};

% Start a log text file to document successes and failures in preprocessing
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(mrvdirup(dtiDir,2),'logs',['PreprocessingLog_SFN_' dateAndTime '.txt']);
fid=fopen(logFile,'w');
startTime = clock;

% Preliminary list of subjects to process, if they have nifti and dicom
% files and a t1 nifti in the t1 directory, and have not already been
% preprocessed.
n=0; % Initialize this counter
fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Checking niftis,dicoms,t1s for all subjects in the dti directory\n\n');
fprintf('Checking niftis,dicoms,t1s for all subjects in the dti directory\n\n');
% call Check... function, but pass alreadyRunFlag = true, so we make a list
% that ONLY includes subjects who have already been run and have a dt6 file
[n,dtiNiftis,gradfilecodes,bvals,freqdirAPflags,t1s]=checkForNiftiDicomT1files(n,dtiDir,subs,fid);

% Print number of directories in age group to log
fprintf(fid,'\nFound %d suitable subjects in the dti directory\n',length(dtiNiftis));
fprintf('\nFound %d suitable subjects in the dti directory\n\n',length(dtiNiftis));

% If we find any subjects to preprocess, go for it.
if~(n==0)

    %------------------------------------------------
    % THIS ACTUALLY DOES THE PREPROCESSING
    %------------------------------------------------
    % Loop over the DTI raw files and preprocess them!
    for(ll=1:length(dtiNiftis))
        dataDir = fileparts(dtiNiftis{ll});
        subDir = fileparts(dataDir);
        [junk,subCode] = fileparts(subDir);
        fprintf('Processing %s... \n',subCode);
        fprintf(fid,'Processing %s... \n',subCode);
        fprintf(fid,'\t Nifti: %s\n',dtiNiftis{ll});
        fprintf(fid,'\t T1: %s\n',t1s{ll});
        fprintf(fid,'\t Bval: %.03f\n',bvals{ll});
        fprintf(fid,'\t GradFileCode: %d\n',gradfilecodes{ll});
        fprintf(fid,'\t FreqDir AP?: %d\n',freqdirAPflags{ll});
        try
            tic
            dtiRawPreprocess(dtiNiftis{ll}, t1s{ll}, bvals{ll}, gradfilecodes{ll}, [],[], freqdirAPflags{ll});
            time=toc;
            fprintf(fid,'Preprocessed %s successfully in %f seconds \n',subCode,time);
            fprintf('Preprocessed %s successfully in %f seconds \n',subCode,time);
            
            % Email me
            status=['Preprocessed ' subCode ' successfully'];
            emailMe(status,'jennifer.yoon@stanford.edu');
            
        catch
            fprintf(fid,'FAILURE: %s at dtiRawPreprocess \n',subCode);
            fprintf('FAILURE: %s at dtiRawPreprocess \n',subCode);
        end

        % Clip negative eigenvalues to 0 for tensor files
        try
            dt6file=fullfile(subDir,'dti30','dt6.mat');
            tensorfile=fullfile(subDir,'dti30','bin','tensors.nii.gz');
            dtiFixTensorsAndDT6(dt6file,tensorfile);
            fprintf(fid,'Tensors clipped for %s \n',subCode);
            fprintf('Tensors clipped for %s \n',subCode);
        catch
            fprintf(fid,'FAILURE TO CLIP TENSORS for %s\n',subCode);
            fprintf('FAILURE TO CLIP TENSORS for %s\n',subCode);
        end
        
    end

else
    fprintf(fid,'Skipping preprocessing loop for dti directory\n');
    fprintf('Skipping preprocessing loop for dti directory\n');
end


totalTime=etime(clock,startTime); 

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);
fprintf('Total running time for script: %f minutes \n',totalTime/60);

fclose(fid); % close out the log file