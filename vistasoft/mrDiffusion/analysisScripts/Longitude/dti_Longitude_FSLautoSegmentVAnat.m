% dti_Longitude_FSLautoSegmentAll
% 
% This script takes a group of subjects and runs dtiAutoSegmentationFsl to
% create a segmentation of gray/white matter using FSLs tools (BET,FIRST
% and FAST). This script just loops over each subject and feeds the function
% the correct inputs:
%   dtiAutoSegmentationFSL(segToRun,[t1File],[outDir],[betFile],[betThresh],[betOpt],[convert],[smooth],[fName])

% 
% We also have previously generated, and inspected, bet images which we
% feed in here. If these files don't exist the function creates one using
% standard parameters.
%
% A log file is also generated and saved within the specified logDir. This
% file contains the subjects names as well as the files used for
% segmentation and the path to the saved data.
%
% HISTORY: 
% 08.16.2010 - LMP wrote the thing. 


%% I. Directory Structure and Subjects

baseDir  = '/biac3/wandell4/data/reading_longitude/';
yr       = {'dti_y1_old'}; %,'dti_y1','dti_y2','dti_y3','dti_y4'}; 
subs     = {'clr0','jh0','pt0','vt0','zs0'};
% subs     = {'ab0','ad0','ada0','ajs0','am0','an0','ao0','ar0','at0','bg0',...
%             'ch0','clr0','cp0','crb0','ctb0','ctr0','da0','dh0','dm0','es0',...
%             'hy0','jh0','js0','jt0','kj0','ks0','lg0','lj0','ll0','mb0','md0',...
%             'mh0','mho0','mm0','mn0','nad0','nf0','nid0','pf0','pt0','rd0','rh0',...
%             'rs0','rsh0','sg0','sl0','ss0','sy0','tk0','tm0','tv0','vh0','vr0','vt0','zs0'};
dirs     = 't1'; 
segToRun = 'fast'; % options = 'fast', 'first', 'all'
smooth   = [0 1 2];      % Specifies smoothing kernal
fName    = 'vAnatomyThr';
betThresh = '0.1';

logFile  = fullfile(baseDir,'longitude_FSLautoSegmentationVAnatLog.txt');
fid      = fopen(logFile,'w');

fprintf(fid,'Running %s for: %d subjects. \nSmoothing Kernel =  %s\n-----------------\n',segToRun,numel(subs),num2str(smooth));

%% II. Loop through subs and runs dtiAutoSegmentationFsl.m
%
startTime = clock;
c = 0;
for dd=1:numel(yr)
    for ii=1:numel(subs)
        
        if strcmp(subs{ii},'clr0') || strcmp(subs{ii},'jh0') || strcmp(subs{ii},'pt0') || strcmp(subs{ii},'vt0') 
            yr   = {'dti_y2'};
        end
        if strcmp(subs{ii},'zs0')
            yr   = {'dti_y3'};
        end

        sub     = dir(fullfile(baseDir,yr{dd},[subs{ii} '*']));
        subDir  = fullfile(baseDir,yr{dd},sub.name);
        t1Dir   = fullfile(subDir, dirs);

        % Setup inputs for the funciton
        t1File   = fullfile(t1Dir,'vAnatomyThr.nii.gz');
        outDir   = fullfile(t1Dir,'seg','fsl','vAnatomy');
        betFile  = fullfile(outDir,'vAnatomyThr_bet.nii.gz');

        if exist(subDir,'file') && exist(t1Dir,'file') && exist(t1File,'file')
            fprintf('Running %s on %s...\n', segToRun, sub.name);
            
                fprintf(fid,'\nSubject:\t%s \nImage:\t\t%s \noutDir:\t%s \nbetFile:\t%s\n',sub.name,t1File,outDir,betFile);
                fprintf('Image:\t %s\noutDir:\t %s\nbetFile: %s\n',t1File,outDir,betFile);
                fprintf('Executing dtiAutoSegmentationFsl! \n...BE PATIENT...\n');
                try
                    dtiAutoSegmentationFsl(segToRun,t1File,outDir,betFile,betThresh,[],[],smooth,fName);
                catch ME
                    c = c+1;
                    elog{c} = subDir;
                    fprintf(fid,'\nSomething went wrong with %s. \n Returned the following error: \n %s\n', sub.name, ME.message);
                    fprintf('\n!!! Something went wrong with %s.\nCheck the log file for more information.\n Moving on...\n\n', sub.name);
                end
        else
            fprintf('\nNo vAnatomy found for %s in %s ...\n', subs{ii}, yr{dd});
            if ~exist(t1File,'file'), fprintf(fid,'Image File not found in %s', t1Dir); end
        end
    end
end


totalTime=etime(clock,startTime);
fprintf('*************\n  DONE!\n');
fprintf('\n Script Completed in a total time of %f minutes\n',totalTime/60);

if ~notDefined('elog')
    fprintf('**********************\nTHE FOLLOWING SUBJECTS RETURNED ERRORS:\n**********************\n');
    fprintf(fid,'**********************\nTHE FOLLOWING SUBJECTS RETURNED ERRORS:\n**********************\n');
    for ee = 1:numel(elog)
        fprintf('%s\n',elog{ee});
        fprintf(fid,'%s\n',elog{ee});
    end
end

    
fclose(fid);





%%


