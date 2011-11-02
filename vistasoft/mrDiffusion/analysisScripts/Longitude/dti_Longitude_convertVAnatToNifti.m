% dti_Longitude_convertVanatToNifti
% 
% This script takes a group of subjects and converts their vAnatomy.dat
% file to a nifti file using:
%  mrAnatConvertVAnatToT1Nifti(vAnat,outFileName)
% 
% The script will look in a subject's t1 folder and if it finds the
% vAnatomy.dat file it will do the conversion.
% 
% A log file is also generated and saved within the specified logDir. This
% file contains the subjects names as well as the files used for
% conversion.
%
% HISTORY: 
% 08.18.2010 - LMP wrote the thing. 


%% I. Directory Structure and Subjects

baseDir  = '/biac3/wandell4/data/reading_longitude/';
yr       = {'dti_y1_old','dti_y1','dti_y2','dti_y3','dti_y4'}; % 
subs     = {'ab0','ad0','ada0','ajs0','am0','an0','ao0','ar0','at0','bg0',...
            'ch0','clr0','cp0','crb0','ctb0','ctr0','da0','dh0','dm0','es0',...
            'hy0','jh0','js0','jt0','kj0','ks0','lg0','lj0','ll0','mb0','md0',...
            'mh0','mho0','mm0','mn0','nad0','nf0','nid0','pf0','pt0','rd0','rh0',...
            'rs0','rsh0','sg0','sl0','ss0','sy0','tk0','tm0','tv0','vh0','vr0','vt0','zs0'};
logFile  = fullfile(baseDir,'longitude_vAnatomyConversionLog3.txt');
fid      = fopen(logFile,'w');

fprintf(fid,'Converting vAnatomy.dat to vAnatomy.nii.gz for: %d subjects. \n-----------------\n',numel(subs));

%% II. Loop through subs and runs dtiAutoSegmentationFsl.m
%
startTime = clock;
c = 0;
for dd=1:numel(yr)
    for ii=1:numel(subs)
        
        sub     = dir(fullfile(baseDir,yr{dd},[subs{ii} '*']));
        subDir  = fullfile(baseDir,yr{dd},sub.name);
        t1Dir   = fullfile(subDir,'t1');
        
        vAnatFile     = fullfile(t1Dir,'vAnatomy.dat');
        outFileName   = fullfile(t1Dir,'vAnatomy.nii.gz');
        thrOutName    = fullfile(t1Dir,'vAnatomyThr.nii.gz');
        
        if exist(subDir,'file') && exist(t1Dir,'file') && exist(vAnatFile,'file')
            if ~exist(outFileName,'file')
                fprintf('\nConverting vAnatomy.dat to vAnatomy.nii.gz for %s...\n', sub.name);
                fprintf(fid,'\nSubject:\t%s \nvAnat:\t\t%s \noutDir:\t%s \n',sub.name,vAnatFile,outFileName);
                fprintf('vAnat:\t %s\noutDir:\t %s\n',vAnatFile,outFileName);
                fprintf('Starting Conversion... \n');
                try
                    mrAnatConvertVAnatToT1Nifti(vAnatFile,outFileName);
                    Command = ['fslmaths ' outFileName ' -thr 0 -uthr 255 ' thrOutName];
                    [status result] = system(Command);
                    if status ~= 0, disp(result); end
                    fprintf('Success!\n');
                catch ME
                    c = c+1;
                    elog{c} = subDir;
                    fprintf(fid,'\nSomething went wrong with %s. \n Returned the following error: \n %s\n', sub.name, ME.message);
                    fprintf('\n!!! Something went wrong with %s.\nCheck the log file for more information.\n Moving on...\n\n', sub.name);
                end
            else
                fprintf('vAnatomy.nii.gz already exists for %s in %s. Skipping...\n',sub.name,yr{dd});
                fprintf(fid,'\nSubject:\t%s \nvAnat:\t\t%s \noutDir:\t%s \n',sub.name,vAnatFile,outFileName);
                fprintf(fid,'vAnatomy.nii.gz already exists for %s in %s. Skipping...\n',sub.name,yr{dd});
            end
        else
            fprintf('\nNo vAnatomy found for %s in %s ...\n', subs{ii}, yr{dd});
            if ~exist(vAnatFile,'file'), fprintf(fid,'/nvAnatFile not found in %s\n', t1Dir); end
        end
    end
end


totalTime=etime(clock,startTime);
fprintf('*************\n  DONE!\n');
fprintf('\n Script Completed in a total time of %f minutes.\n\n',totalTime/60);

if ~notDefined('elog')
    fprintf('**********************\nTHE FOLLOWING SUBJECTS RETURNED ERRORS:\n**********************\n')
    fprintf(fid,'**********************\nTHE FOLLOWING SUBJECTS RETURNED ERRORS:\n**********************\n')
    for ee = 1:numel(elog)
        fprintf('%s\n',elog{ee});
        fprintf(fid,'%s\n',elog{ee});
    end
end

    
fclose(fid);





%%


