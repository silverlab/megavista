script dti_Longitude_NormalizeMoriFibersDensity

%Generate and density normalize Mori fibers - for all the subjects in the londitudial dataset
%ER 05/2009

warning('off'); clear;

addpath(genpath('~/vistasoft'));
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008/'));

minDist=1.74; %parameter for min dist from a fiber end point to GM mask in order to keep the fiber in the MoriGroupsConnectingGM
load('/biac3/wandell4/users/elenary/longitudinal/subjectCodes');
%subjectID={'at040918', 'at051008', 'at060825', 'at070815', 'mho040625', 'mho050528', 'mho060527', 'mho070519'};
subjectID=subjectCodes;
project_folder='/biac3/wandell4/data/reading_longitude/dti_y1234/';

%%%%%%%
%Compute MoriGroups.mat & MoriGroupsConnectingGM
%%%%%%%%%%
for s=1:size(subjectID, 2); 

    cd([project_folder subjectID{s}]);
    dt6File=fullfile(pwd, 'dti06trilinrt', 'dt6.mat')
    if (~exist(fullfile(fileparts(dt6File), 'fibers', 'MoriGroupsConnectingGM.pdb'), 'file'))
    %Step 1. Prepare files for density normalization
    %1.1. Prepare a safe Brain Mask and average raw diffusion data across reps.
    %= Safe Brain Mask excludes voxels that have a raw data value (any gradient direction) of zero. 
    dtiRawdir=fullfile(project_folder, subjectID{s}, 'raw');  
    
    %= Prepare average aligned raw dti data, accompanied by bvals and
    %bvecs. 
    dtiRawAverage(fullfile(dtiRawdir, 'dti_g13_b800_aligned.nii.gz'), fullfile(dtiRawdir, 'dti_g13_b800_aligned.bvecs'),fullfile(dtiRawdir, 'dti_g13_b800_aligned.bvals'));
    dtiMakeBrainMaskSafe(fullfile(pwd, 'dti06trilinrt'), fullfile('raw', 'dti_g13_b800_aligned.nii.gz'));
    %1.2 Create contrack parameters file
    %P parameters taken from Tony's example configuration for density
    %normalization. 
    if (~exist(fullfile(fileparts(dt6File), 'bin', 'pddDispersion.nii.gz'), 'file'))
        
    unix(['cp ' fullfile(pwd, 'dti06trilin', 'bin', 'pddDispersion.nii.gz') ' ' fullfile(fileparts(dt6File), 'bin')]);
    end
    spName=fullfile('fibers', 'conTrack', 'ctr_paramsDN.txt');
    p.dt6File=dt6File; p.roiMaskFile='brainMask.nii.gz';
    p.timeStamp=datestr(now,30);p.roi1File=[]; p.roi2File=[]; p.wm=false;p.pddpdf=true;p.dSamples=300;p.maxNodes=300;p.minNodes=10; p.stepSize=1;
    p = ctrInitParamsFile(p, spName);  %saved in root/fibers/conTrack and refers to image directory dti06/bin/ (with pdf and the brain mask)
    
    
    %Step2. Produce full brain STT fibers (I used parameters within dti_Longitude_TrackNCullAll.m) and Mori-classify them. 
    %2.1 Perform full brain tractography: Track all white matter fibers in the native subject space. We do this by
    % seeding all voxels with high FA (>0.3). dtiFindMoriTract will by
    % default perform whole brain tractography. We will not save it because
    % this kind of fiberset is about 500MB. 
    z
    %2.2 Find Mori tracts
    dt = dtiLoadDt6(dt6File);
    fg=dtiFindMoriTracts(dt6File);
    
    % Only fibers whose both endpoints are within the gray matter (roi prepared) will be considered.  
    % Note: here we could have simply used fgM=dtiGetFibersConnectingGM(fg, dt);
    % But we want to save both MoriGroups.mat and MoriGroupsConnectingGM.mat
    % And to save space we are representing MoriGroupsConnectingGM.mat 
    morifibersFile=fullfile('dti06trilinrt', 'fibers', 'MoriGroups.mat'); 
    dtiWriteFiberGroup(fg, morifibersFile);
    
    morifibersGM=fullfile('dti06trilinrt', 'fibers',  'MoriGroupsConnectingGM.mat');
    [fgOut,contentiousFibers, keep, keepID] = dtiIntersectFibersWithRoi([], {'and', 'both_endpoints'}, minDist, roi, fg);
    dtiWriteFibersSubset(morifibersFile, find(keep), morifibersGM, fgOut.name);
        
    %Save the data in pdb format /temporarily/
    dtiWriteFibersPdb(fgOut, dt.xformToAcpc, fullfile(fileparts(dt6File), 'fibers', 'MoriGroupsConnectingGM.pdb')); 
    end
end

return
%Some of the subjects did not get a pdb exported. 
for s=1:size(subjectID, 2); 
    cd([project_folder subjectID{s}]);
    dt6File=fullfile(pwd, 'dti06trilinrt', 'dt6.mat');
    dt = dtiLoadDt6(dt6File);
    morifibersGM=fullfile('dti06trilinrt', 'fibers',  'MoriGroupsConnectingGM.mat');
    if ~exist(fullfile(fileparts(dt6File), 'fibers', 'MoriGroupsConnectingGM.pdb'), 'file')
    fg=dtiLoadFiberGroup(morifibersGM);
    %Save the data in pdb format /temporarily/
    dtiWriteFibersPdb(fg, dt.xformToAcpc, fullfile(fileparts(dt6File), 'fibers', 'MoriGroupsConnectingGM.pdb')); 
    end
end   

%%%%%%%%%
%Shoot trueSAs (perform after all the prev steps done)

return

%RUN to cleanup if no truesa procs are currently running
for s=1:size(subjectID, 2) 
    cd([project_folder subjectID{s}]);
if ( (exist('dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.ind', 'file') & exist('dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.TMP', 'file'))) 
    display(['removing a TMP for ' subjectID{s}]);  %what if i just started it?
        !rm dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.TMP
    end
end
%

return
%infinite loop sending the jobs -- finish when found 108 culled SLF groups) -- for it to
%work must have run at least one manually
%
while (size(findstr('MoriGroupsConnectingGM_DN.ind', ls('/biac3/wandell4/data/reading_longitude/dti_y1234/*/dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.ind')), 2)<108) 

for s=1:size(subjectID, 2) 

    cd([project_folder subjectID{s}]);
   %pause(260)
%clean up if IND was earlier computed
    if ( (exist('dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.ind', 'file') & exist('dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.TMP', 'file'))) 
    display(['removing a TMP for ' subjectID{s}]);  %what if i just started it?
        !rm dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.TMP
    end

    %check if there are avail cores
 %   if (size(findstr('MoriGroupsConnectingGM_DN.TMP', ls('/biac3/wandell4/data/reading_longitude/dti_y1234/*/dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.TMP')), 2)>=30)
 %   display('all processes busy');
 %       continue
 %   end

    %if(~exist('dti06trilinrt/fibers','dir')), mkdir('dti06trilinrt/fibers'); end
%If no resulting DN file and no flag
    if ( (exist('dti06trilinrt/fibers/MoriGroupsConnectingGM.pdb', 'file') & ~exist('dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.ind', 'file')) & ~exist('dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.TMP', 'file')) 
   %place a flag
      display(['Placing a flag and starting a trueSA for' subjectID{s}]);  
     save('dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.TMP', 's'); %flag: we are workin on it
    else continue
    end
    system(['/biac3/wandell4/users/elenary/density_normalization/scripts/runSAmpi.sh ' project_folder filesep subjectID{s} filesep 'dti06trilinrt  MoriGroupsConnectingGM.pdb MoriGroupsConnectingGM_DN.pdb' ' &']); 
    
end
end

return
%%%%%%%%%%% RUN AFTER ALL TRUESA and VALIDATION JOBS DONE
%Tranform ind to mat
for s=1:108
    cd([project_folder subjectID{s}]);
    dt6File=fullfile('dti06trilinrt', 'dt6.mat');
	morifibersGM=fullfile('dti06trilinrt', 'fibers',  'MoriGroupsConnectrningGM.mat');
	

    %Get the pdb back to mat, incorporating the indices
    load(morifibersGM); %I know it will load fghandle. Reading it with dtiReadFibers would prematurely split fg into subgroups--FIX NEEDED
    load(fghandle.parent); %I know parent is a fg with subgroups, so cant use dtiReadFibers either. This fg is MoriGroups.mat
    fid=fopen(fullfile(fileparts(dt6File), 'fibers', ['MoriGroupsConnectingGM_DN.ind']));
    %TrueSA solution are indices of fibers to keep--in the space of MoriGroupsConnectingGM. PLUS1!!! (those indices count from 0)
    DN_ind=textscan(fid, '%d');DN_ind=DN_ind{1}; fclose(fid);
    
    dtiWriteFibersSubset('MoriGroups', fghandle.ids(DN_ind+1), fullfile(fileparts(dt6File), 'fibers', 'MoriGroupsConnectingGM_DN.mat'), 'MoriGroupsConnectingGMDensityNormalized');
    unix(['rm ' fullfile(fileparts(dt6File), 'fibers', 'MoriGroupsConnectingGM_DN.pdb')]);

end

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Run BM 10 times on each of 4 time points for 'at'. BM robustness tests.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subjectID={'at040918', 'at051008', 'at060825', 'at070815'};
project_folder='/biac3/wandell4/data/reading_longitude/dti_y1234/';

%Submit blue matter jobs
for s=1:4
cd([project_folder subjectID{s}]);

	dt6File=fullfile('dti06trilinrt', 'dt6.mat');
	dt = dtiLoadDt6(dt6File);
	morifibersGM=fullfile('dti06trilinrt', 'fibers',  'MoriGroupsConnectingGM.mat');
	fgOut=dtiLoadFiberGroup(morifibersGM); 
	%Save the data in pdb format /temporarily/
	dtiWriteFibersPdb(fgOut, dt.xformToAcpc, fullfile(fileparts(dt6File), 'fibers', 'MoriGroupsConnectingGM.pdb')); 
	for trial=1:10
	system(['/biac3/wandell4/users/elenary/density_normalization/scripts/runSAmpi.sh ' project_folder subjectID{s} filesep 'dti06trilinrt MoriGroupsConnectingGM.pdb MoriGroupsConnectingGM_DN' num2str(trial) '.pdb &']); 
    
    end

end

%Tranform ind to mat
for s=1:4
    cd([project_folder subjectID{s}]);
    dt6File=fullfile('dti06trilinrt', 'dt6.mat');
	morifibersGM=fullfile('dti06trilinrt', 'fibers',  'MoriGroupsConnectingGM.mat');
	
    for trial=1:10
    %Get the pdb back to mat, incorporating the indices
    load(morifibersGM); %I know it will load fghandle. Reading it with dtiReadFibers would prematurely split fg into subgroups--FIX NEEDED
    load(fullfile('dti06trilinrt', 'fibers',fghandle.parent)); %I know parent is a fg with subgroups, so cant use dtiReadFibers either. This fg is MoriGroups.mat
    fid=fopen(fullfile(fileparts(dt6File), 'fibers', ['MoriGroupsConnectingGM_DN' num2str(trial) '.ind']));
    %TrueSA solution are indices of fibers to keep--in the space of MoriGroupsConnectingGM. PLUS1!!! (those indices count from 0)
    DN_ind=textscan(fid, '%d');DN_ind=DN_ind{1}; fclose(fid);
    
    dtiWriteFibersSubset('MoriGroups', fghandle.ids(DN_ind+1), fullfile(fileparts(dt6File), 'fibers', ['MoriGroupsConnectingGM_DN' num2str(trial) '.mat']), ['MoriGroupsConnectingGMDensityNormalized  Trial' num2str(trial)]);
    unix(['rm ' fullfile(fileparts(dt6File), 'fibers', ['MoriGroupsConnectingGM_DN' num2str(trial) '.pdb'])]);
    end
    
    unix(['rm ' fullfile(fileparts(dt6File), 'fibers', 'MoriGroupsConnectingGM.pdb')]);
end

return
