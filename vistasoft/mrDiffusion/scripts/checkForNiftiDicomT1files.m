function [n,dtiNiftis,gradfilecodes,bvals,freqdirAPflags,t1s,clobberFlags]=checkForNiftiDicomT1files(n,thisDir,subs,fid,alreadyRunFlag)

% checkForNiftiDicomT1files
%
% Usage:
% [n,dtiNiftis,gradfilecodes,bvals,freqdirAPflags,t1s,clobberFlags]=checkForNiftiDicomT1files(n,thisDir,subs,fid,[alreadyRunFlag=false]);
%
% Called by dti_FFA_preprocessScript.m
% Checks for all the necessary information required for dtiRawPreprocess.m
% by looking within a particular directory (thisDir) and looping through a
% list of subjects (subs). It then creates arrays with lists of nifti
% files, gradcodes, bvalues, frequency-encode direction AP flags, and t1
% files (output arguments) -- as well as a counter (n).  
%
% Errors are logged in a file specified before calling the function (fid).
%
% At the very end, subjects with existing dt6 files are excluded. 
%
% By: DY, 2008/02/24
% Modified: DY 2008/09/09 -- added the "alreadyRunFlag", which is set to
% false by default. If it is set to true, then we will reverse the check
% for dt6 files. When it is set to false (default), we exclude subjects
% from the list who already have dt6 files. When it is set to true, we only
% INCLUDE subjects who already have dt6 files. This is helpful if we want
% to have a script to fix/reprocess subjects who have already been run.
% Modified: 2010/01/25 -- Fix "alreadyRun" option to set the CLOBBERFLAGS
% variable appropriately (clobber==true if eddy current correction happened
% before 8/27/2009: the date when I installed this fix to my svn)

if notDefined('alreadyRunFlag'), alreadyRunFlag=false; end

for jj=1:length(subs)

    % Go into the raw directory to find necessary information
    rawDir = fullfile(thisDir,subs{jj},'raw');
    if ~isdir(rawDir)
        % If rawDir does not exist, skip all following statements and go to
        % the next iteration of the loop
        continue 
    end
    
    cd(rawDir);
    dn = dir('*.nii.gz*');

    % If the DTI nifti file exists, add it to the list of DTI nifti
    % files to process, and get BVAL, GRADFILECODE and PHASEENCODE
    % information from the dicom header.
    if (alreadyRunFlag==false && ~(length(dn)==1)) % If no dti nifti, or multiple, ERROR
        fprintf(fid,'Problem with nifti files for %s \n',subs{jj});
        fprintf('Problem with nifti files for %s \n',subs{jj});
        continue %skip to next subject in loop

    elseif (alreadyRunFlag==false && length(dn)==1) % Proceed if dti nifti exists, and is the only one

        dicomDir = fullfile(rawDir,dn.name(1:end-7));
        dtiNiftis{n+1} = fullfile(rawDir,dn.name);
        
    elseif alreadyRunFlag==true && length(dn)>1 % Set dtiNifti to the raw nifti if flag==true
        
        % Find the one that is just called dti_g###_b###.nii.gz
        junk1=cellfun('isempty',strfind({dn.name},'b0'));
        junk2=cellfun('isempty',strfind({dn.name},'aligned'));
        therawdn=dn(find(junk1+junk2==2)).name;
        dicomDir = fullfile(rawDir,therawdn(1:end-7));
        dtiNiftis{n+1} = fullfile(rawDir,therawdn);
        
        % DELETE any old "aligned" files -- if they are left and clobber is
        % set to false, we won't be taking into account the new tensor
        % fitting method (as of 1/2010: trilinear instead of bspline)
        tmp=dir('*aligned*');
        if ~isempty(tmp)>0
            !rm -r *aligned*
            disp('Removing *aligned* files from the raw directory');
        end
        
        % Set clobberFlag to TRUE if the subject was preprocessed before
        % the eddy current correction bug was corrected; set clobberFlag to
        % FALSE if the subject was processed after -- this means that we
        % can leave the eddy correction file, which takes the longest to
        % compute. The date I wrote my eddycorrect reprocessing code was
        % 9/9/2009, so I conservatively reprocess all files (aka,
        % CLOBBER=TRUE) if the ec file was from before that date. 
        eddyBugDate = datenum([2008 08 26 12 12 12]);
        ecFile = 'dti_g865_b900_ecXform.mat';
        if exist(ecFile,'file')
            tmp=dir(ecFile);
            ecFileDate = datenum(tmp.date);
            if (eddyBugDate>ecFileDate) % recompute buggy eddy current correction file
                clobberFlags(n+1)=true;
            else % don't recompute eddy current correction if file created after 9/9/2009
                clobberFlags(n+1)=false;
            end
        else
            clobberFlags(n+1)=false;
        end
        
    end
    
    % Check if dicoms exist
    if exist(fullfile(dicomDir,'I0001.dcm'))
        info = dicominfo(fullfile(dicomDir,'I0001.dcm'));
        gradfilecodes{n+1} = info.Private_0019_10b2;
        % Divide b-value by 1000 (900=0.9)
        bvals{n+1} = info.Private_0019_10b0/1000;
        % If phase encode direction is L/R and frequency encode
        % direction is A/P (two are orthogonal), info field will return
        % ROW and a special flag should be set in dtiRawPreprocess
        if strcmp(info.InPlanePhaseEncodingDirection,'ROW')
            freqdirAPflags{n+1}=1;
        else
            freqdirAPflags{n+1}=0;
        end

        % If dicom and nifti exist, check if t1.nii.gz exists and is in proper location
        t1 = fullfile(thisDir,subs{jj}, 't1', 't1.nii.gz');
        if(exist(t1))
            t1s{n+1} = t1;
            fprintf(fid,'All files required for preprocessing found for %s \n',subs{jj});
            fprintf('All files required for preprocessing found for %s \n',subs{jj});

            % Since everything exists (dicoms, nifti, t1), update the
            % counter. All other indices are set to n+1 because we
            % check for files for the n+1th subject assuming all files
            % will be present, but only update N if all files are
            % actually found.
            n = n+1;

        else
            fprintf(fid,'T1 nifti not found in T1 directory for %s \n',subs{jj});
            fprintf('T1 nifti not found in T1 directory for %s \n',subs{jj});
        end

    else % If no dicom found, ERROR
        fprintf(fid,'No dicom file was found for %s \n',subs{jj});
        fprintf('No dicom file was found for %s \n',subs{jj});
    end

end

% This code deals with the event that there are no suitable subjects in the
% entire directory to process. 
if(n==0)
    dtiNiftis=[];
    gradfilecodes=[];
    bvals=[];
    freqdirAPflags=[];
    t1s=[];
    fprintf('No subjects found in this directory, setting all output variables to empty \n');

% If there are some suitable subjects, make sure they have not already bene
% preprocessed. If they have been, weed them out. 
else
    fprintf('At least one subject found in this directory \n');
    % Create an array PROCESSTHESE, with indices set to false if there
    % is an existing dti30 directory and dt6.mat file
    
    if alreadyRunFlag==false % exclude subjects who already have a dt6
        processThese = true(1,n);
        for(kk=1:n)
            dataDir = fileparts(dtiNiftis{kk});
            subDir = fileparts(dataDir);
            [junk,subCode] = fileparts(subDir);
            if(exist(fullfile(subDir,'dti30'),'dir')&&exist(fullfile(subDir,'dti30','dt6.mat'),'file'))
                fprintf(fid,'%s dt6 exists -- skipping \n', subCode);
                fprintf('%s dt6 exists -- skipping \n', subCode);
                processThese(kk) = false;
            end
        end

     elseif alreadyRunFlag==true % include ONLY subjects who already have a dt6
         processThese = true(1,length(dtiNiftis));
%         for(kk=1:n)
%             dataDir = fileparts(dtiNiftis{kk});
%             subDir = fileparts(dataDir);
%             [junk,subCode] = fileparts(subDir);
%             if(exist(fullfile(subDir,'dti30'),'dir')&&exist(fullfile(subDir,'dti30','dt6.mat'),'file'))
%                 fprintf(fid,'%s dt6 exists -- including \n', subCode);
%                 fprintf('%s dt6 exists -- including \n', subCode);
%                 processThese(kk) = true;
%             end
%         end
    end

    % Make a new list of files to process excluding those
    % identified above as already finished
    dtiNiftis = dtiNiftis(processThese);
    gradfilecodes = gradfilecodes(processThese);
    bvals = bvals(processThese);
    freqdirAPflags = freqdirAPflags(processThese);
    t1s = t1s(processThese);
end

return