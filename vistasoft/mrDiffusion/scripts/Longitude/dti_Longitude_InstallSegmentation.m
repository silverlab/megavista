% dti_Longitude_InstallSegmentation
% 
% This script will loop through a group of subjects and install a
% segmentation nifti for use with their fMRI data. 
% 
% In this particular case we're installing semgentations only in year 1
% (fmri) using segmentations that were done using FSL on the
% vAnatomy.nii.gz file located in each subject's dti_y1_old directory
% (segDir).
% 
% The script is setup to install the segmentations in the data found in
% each subject's PhaseW directory in fmri. 
% 
% The script sets the volume path as well, using setVAnatomyPath -
% currently is sets that path to the vAnatomy.dat file in the subject's t1
% directory in dti_y1_old. I'm not sure if this should be done in everyone,
% or if the volume path has already been set and does not have to be set
% again. It looks like the volume paths were set in windows with arbitrary
% drive letter assignments being used in the path. This could prove to be
% be problematic going forward as this script sets the paths using typical
% unix path structure.
% 
% The results of the segmentations are saved out to a log file. In that
% text file you can see the subject's directory and the files that were set
% for the volume path and segmentation file used. 
% 
% It is also the case for some subjects that they already have a
% classification installed (e.g, ajs). I'm not sure if we want to reinstall
% the segmentation for subjects such as this. Also note that because of the
% windows generated path structure they can't be viewed on Linux systems.
% This is problematic because the script as written can't differentiate
% between the subjects who already have segmentations installed and ones
% that do not. 
% 
%  Uses functions outlined in % s_GrayAndVolumeSetup.m
%
% HISTORY: 08.18.2010 - LMP wrote the thing. 


%% I. Directory Structure and Subjects

baseDir  = '/biac3/wandell4/data/reading_longitude/';
subs     = {'ad0','clr0','dh0','dm0','jh0','jt0','lg0','lj0','ll0','mh0','nf0','pf0','pt0','rs0','rsh0','sl0','sy0','tv0','vt0','zs0'};
% subs     = {'ab0','ad0','ada0','ajs0','am0','an0','ao0','ar0','at0','bg0',...
%             'ch0','clr0','cp0','crb0','ctb0','ctr0','da0','dh0','dm0','es0',...
%             'hy0','jh0','js0','jt0','kj0','ks0','lg0','lj0','ll0','mb0','md0',...
%             'mh0','mho0','mm0','mn0','nad0','nf0','nid0','pf0','pt0','rd0','rh0',...
%             'rs0','rsh0','sg0','sl0','ss0','sy0','tk0','tm0','tv0','vh0','vr0','vt0','zs0'};      
logFile  = fullfile(baseDir,'longitude_InstallSegmentation.txt');
fid      = fopen(logFile,'w');


%% II. Loop through subs and installs the segmentations
fprintf(fid,'Installing segmentation for: %d subjects. \n-----------------\n',numel(subs));
startTime = clock;
c = 0;

for dd=1:numel(yr)
    for ii=1:numel(subs)
        yr       = {'fmri'};
        dtYr     = 'dti_y1_old';
        
        if strcmp(subs{ii},'clr0') || strcmp(subs{ii},'jh0') || strcmp(subs{ii},'pt0') || strcmp(subs{ii},'vt0') 
            yr   = {'fmri_y2'};
            dtYr = 'dti_y2';
        end
        if strcmp(subs{ii},'zs0')
            yr   = {'fmri_y3'};
            dtYr = 'dti_y3';
        end
        
        % fMRI data
        sub        = dir(fullfile(baseDir,yr{dd},[subs{ii} '*_PhaseW_*']));
        subDir     = fullfile(baseDir,yr{dd},sub.name);
        % DTI data (for Anatomy)
        subDt      = dir(fullfile(baseDir,dtYr,[subs{ii} '*']));
        subDirDt   = fullfile(baseDir,dtYr,subDt.name);
        t1Dir      = fullfile(subDirDt,'t1');
        vAnatFile  = fullfile(t1Dir,'vAnatomy.dat');
        segDir     = fullfile(t1Dir,'seg','fsl','vAnatomy');
        
        if exist(subDir,'file')
            try
                % Initialize the key variables and data path:
                cd(subDir);
                vw_ip       = initHiddenInplane(); 
                anatDir     = t1Dir; 
                volAnat     = vAnatFile; 
                volSegm     = fullfile(segDir,'vAnatomyThr_fastClassSmooth1_clean.nii.gz'); 
                nGrayLayers = 4;
                
                % Set the volume anatomy path and load the view:
                setVAnatomyPath(volAnat);
                vw_vol = initHiddenVolume(); 
                
                % Grow necessary gray layers from volume and load the view:
                buildGrayCoords(vw_vol, [], [], {volSegm}, nGrayLayers);
                vw_gray = initHiddenGray();
                
                clear globals 
            catch ME
                c = c+1;
                elog{c} = subDir;
                fprintf(fid,'\nSomething went wrong with %s. \n Returned the following error: \n %s\n', sub.name, ME.message);
                fprintf('\n!!! Something went wrong with %s.\nCheck the log file for more information.\n Moving on...\n\n', sub.name);
            end
        else
            fprintf('\nNo Data found for %s in %s ...\n', subs{ii}, yr{dd});
            if ~exist(vAnatFile,'file'), fprintf(fid,'/nFile not found in %s\n', t1Dir); end
        end
    end
end
                
totalTime = etime(clock,startTime);
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