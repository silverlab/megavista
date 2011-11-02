function dti_FFA_createDTIniftis(baseDir,fid);

% Usage: dti_FFA_createDTIniftis(baseDir);
%
% baseDir = '/biac1/kgs/project/'
% fid = file id for the text log being created by dti_FFA_preprocessScript
%
% By: DY 2008/06/03
%
% This function will go through a list of directories in BASEDIR and create
% dti nifti files for all subjects that do not currently have a dti nifti
% file. 
%
% IMPORTANT: requires all raw dicoms to be stored in DTI directory at
% subject's top level in a directory called 'dti'

% Force preprocessing to handle adults, adolescents and kids in that order
s1 = dir('*adult*');  s2 = dir('*adol*');  s3 = dir('*kid*');  
subs={s1.name s2.name s3.name}; clear s1 s2 s3;


for ii=1:length(subs)
    thisDir=fullfile(baseDir,subs{ii});
    if ~isdir(fullfile(thisDir,'dti'))
        fprintf(fid,'Raw dti dir NOT found for %s \n',subs{ii});
        fprintf('Raw dti dir NOT found for %s \n',subs{ii});
        continue
    elseif ~exist(fullfile(thisDir,'dti','I0001.dcm'))
        fprintf(fid,'Dicom NOT found for %s \n',subs{ii});
        fprintf('Dicom NOT found for %s \n',subs{ii});
        continue
    else       
        info = dicominfo(fullfile(thisDir,'dti','I0001.dcm'));
        gradfilecode = info.Private_0019_10b2;
        bval = info.Private_0019_10b0/1000;
        dtiDirName = ['dti_g' num2str(gradfilecode) '_b' num2str(bval*1000)];
        mkdir(fullfile(thisDir,'raw')); 
        movefile(fullfile(thisDir,'dti'), fullfile(thisDir,'raw',dtiDirName));
        cd(thisDir)
        tic
        niftiFromDicom(fullfile(thisDir,'raw',dtiDirName));
        time=toc
        fprintf(fid,'Created DTI nifti successfully in %f seconds for %s \n',time,subs{ii});
        fprintf('Created DTI nifti successfully in %f seconds for %s \n',time,subs{ii});
        
        % Check that only one nifti was created and make sure it has the
        % same name as the directory
        cd(fullfile(thisDir,'raw'))
        dn = dir('*.nii.gz*');
        dnnii = [dtiDirName '.nii.gz'];
        if (length(dn)==1) % If there is exactly one dti nifti
            movefile(dn.name, dnnii);
            fprintf(fid,'Saved %s \n',fullfile(thisDir,'raw',dnnii));
            fprintf('Saved %s \n',fullfile(thisDir,'raw',dnnii));
        end
    end
end


    