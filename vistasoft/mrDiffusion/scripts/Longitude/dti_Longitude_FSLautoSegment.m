% dti_Longitude_FSLautoSegment
% 
% This script takes a group of subjects and runs dtiAutoSegmentationFsl to
% create a segmentation of gray/white matter using FSLs tools (BET,FIRST
% and FAST). This script just loops over each subject and feeds the function
% the correct inputs:
%   dtiAutoSegmentationFSL(segToRun,[t1File],[outDir],[betFile],[betThresh],[betOpt])
%
% The novel aspect of this particular script is that it recursively
% searches through each year in reverse order looking for a subject's
% T1.nii.gz. The reason for this is that each year the subject's t1 was
% aligned to and averaged with the previous year, thus yeilding a
% "cleaner" image. We would like to feed FSL the best image we have
% available, thus we search recursively in reverse order.
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
% 08.10.2010 - LMP wrote the thing. 


%% I. Directory Structure and Subjects

baseDir  = '/biac3/wandell4/data/reading_longitude/';
yr       = {'dti_y4','dti_y3','dti_y2','dti_y1'};
subs     = {'ab0','ad0','ada0','ajs0','am0','an0','ao0','ar0','at0','bg0',...
            'ch0','clr0','cp0','crb0','ctb0','ctr0','da0','dh0','dm0','es0',...
            'hy0','jh0','js0','jt0','kj0','ks0','lg0','lj0','ll0','mb0','md0',...
            'mh0','mho0','mm0','mn0','nad0','nf0','nid0','pf0','pt0','rd0','rh0',...
            'rs0','rsh0','sg0','sl0','ss0','sy0','tk0','tm0','tv0','vh0','vr0','vt0','zs0'};
dirs     = 't1'; 
segToRun = 'fast'; % options = 'fast', 'first', 'all'
smooth   = 2;      % Specifies smoothing kernal

logFile  = fullfile(baseDir,'longitude_FSLautoSegmentationLog.txt');
fid      = fopen(logFile,'w');

fprintf(fid,'Running %s for: %d subjects. \nSmoothing Kernel =  %s\n-----------------\n',segToRun,numel(subs),num2str(smooth));

%% II. Loop through subs and runs dtiAutoSegmentationFsl.m
%
startTime = clock;

for ii=1:numel(subs)
    hasT1 = 0;
    for dd=1:numel(yr)
        if hasT1 == 0;
            sub     = dir(fullfile(baseDir,yr{dd},[subs{ii} '*']));
            subDir  = fullfile(baseDir,yr{dd},sub.name);
            t1Dir   = fullfile(subDir, dirs);
            
            % Setup inputs for the funciton
            t1File   = fullfile(t1Dir,'t1.nii.gz');
            outDir   = fullfile(t1Dir,'seg','fsl');
            betFile  = fullfile(t1Dir,'seg','t1_bet.nii.gz');
            
            if exist(subDir,'file') && exist(t1Dir,'file') && exist(t1File,'file')
                fprintf('Running %s on %s...\n', segToRun, sub.name);
                hasT1 = 1;
            end
            if ~exist(t1File,'file')
                disp(['No data found for ' subs{ii} ' in ' yr{dd} '. Looking in ' yr{(dd+1)} '...']);
            end
        end
    end
   % If the segmentation file does not exist run this code - this will
   % allow us to loop through all of the subjects and run the
   % classification. 
    fprintf(fid,'\nSubject:\t%s \nT1:\t\t%s \noutDir:\t%s \nbetFile:\t%s\n',sub.name,t1File,outDir,betFile);
    fprintf('T1:\t %s\noutDir:\t %s\nbetFile: %s\n',t1File,outDir,betFile);
    fprintf('Executing dtiAutoSegmentationFsl! \n...BE PATIENT...\n');
    dtiAutoSegmentationFsl(segToRun,t1File,outDir,betFile,[],[],[],smooth);
end

fclose(fid);
totalTime=etime(clock,startTime);
fprintf('*************\n  DONE!\n');
fprintf('\n Script Completed in a total time of %f minutes\n',totalTime/60);





%%


