% dti_FFA_preprocessScript_dp
%
% Usage: dti_FFA_preprocessScript_dp
%
% By: DY 2008/09/11 (modified from dti_FFA_preprocessScript_fixEddyRT
%
% This script will go through the Kids project DTI DP directory, and look for
% suitable subjects (already preprocessed). Errors and progress are logged
% to a text file. 
%
% The goal is to fix these subjects' previous preprocessing (to correct for
% a bug where eddy current correction was improperly implemented) and also
% to implement robust tensor fitting.
%
% The end result will be that the original DTI30 directory will be moved to
% DTI30_OLD_YYMMDD. Then you will have a new DTI30 directory, plus an
% additional directory for your robust tensor fit: DTI30_RT.
%
% So if everything is run correctly, you will have three DTI30 directories.
%
% NOTE: It's very important to run this script on R2008a, with the spm
% directory set to /usr/local/matlab/toolbox/mri/spm5_r2008 (you can check
% by typing "which spm"). 
%
% NOTE: There is an error in parsing directory names (when it says
% "computing inverse transformation after doing the tensor fit, it will
% just freeze/hang there). So I can change the dti dirname from dti30 to
% dti_dp. I can use mv to change the name back later. ACTUALLY, the better
% solution may be to change the other directory names and leave the outdir
% name to DTI30. 
%
% Only running on subjects in the dp_presentation directory, as I'm having
% a lot of trouble with the scripting... arg. 


% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\dp_presentation\';
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/dp_presentation/';
end
cd(dtiDir); s = dir('*0*');  subs={s.name};

% Start a log text file to document successes and failures in preprocessing
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(mrvDirup(dtiDir,2),'logs',['REPROCESS_DP_Log_' dateAndTime '.txt']);
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
[n,dtiNiftis,gradfilecodes,bvals,freqdirAPflags,t1s]=checkForNiftiDicomT1files(n,dtiDir,subs,fid,true);

% Print number of directories to log
fprintf(fid,'\nFound %d suitable subjects in the dti directory\n',length(dtiNiftis));
fprintf('\nFound %d suitable subjects in the dti directory\n\n',length(dtiNiftis));

% If we find any subjects to preprocess, go for it.
if~(n==0)

    %------------------------------------------------
    % THIS ACTUALLY DOES THE PREPROCESSING
    %------------------------------------------------
    % Loop over the DTI raw files and preprocess them!
    for(ll=2:length(dtiNiftis))
        
        ll=5
        dataDir = fileparts(dtiNiftis{ll});
        subDir = fileparts(dataDir);
        [junk,subCode] = fileparts(subDir);
        fprintf('REPROCESSING %s... \n',subCode);
        fprintf(fid,'REPROCESSING %s... \n',subCode);
        fprintf(fid,'\t Nifti: %s\n',dtiNiftis{ll});
        fprintf(fid,'\t T1: %s\n',t1s{ll});
        fprintf(fid,'\t Bval: %.03f\n',bvals{ll});
        fprintf(fid,'\t GradFileCode: %d\n',gradfilecodes{ll});
        fprintf(fid,'\t FreqDir AP?: %d\n',freqdirAPflags{ll});
        
        % Input arguments needed for Reprocess and RT functions
        dtiDirName=fullfile(subDir,'dti30');
        dt6_rtDir=fullfile(subDir,'dti30_rt');
        rawBaseName=['dti_g' num2str(gradfilecodes{ll}) '_b' num2str(bvals{ll}*1000)];
        aligned=[rawBaseName '_aligned'];
        
        cd(subDir);
        
        keyboard;
        
        try
            tic
            dtiRawPreprocess(fullfile(subDir,'raw',[rawBaseName,'.nii.gz']),t1s{ll},[],[],false,dtiDirName,[],0);
            time=toc;
            fprintf(fid,'Preprocessed %s successfully in %f seconds \n',subCode,time);
            fprintf('Preprocessed %s successfully in %f seconds \n',subCode,time);
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
        
        % Robust tensor fitting
        try
            dwRawAligned=fullfile(subDir,'raw',[aligned '.nii.gz']);
            alignedBvecsFile=fullfile(subDir,'raw',[aligned '.bvecs']);
            alignedBvalsFile=fullfile(subDir,'raw',[aligned '.bvals']);
            dtiRawFitTensor(dwRawAligned, alignedBvecsFile, alignedBvalsFile, dt6_rtDir, [], 'rt');
            fprintf(fid,'Robust tensor fit calculated for %s successfully in %f seconds \n',subCode,time);
            fprintf('Robust tensor fit calculated for %s successfully in %f seconds \n',subCode,time);
        catch
            fprintf(fid,'FAILURE: %s at dtiRawFitTensor robust tensor fitting \n',subCode);
            fprintf('FAILURE: %s at ddtiRawFitTensor robust tensor fitting \n',subCode);
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