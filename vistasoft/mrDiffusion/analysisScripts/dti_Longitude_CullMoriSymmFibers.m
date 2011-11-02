%findMoriGroups for new (symmetrified) Mori atlas, then cull
%Only for the 108 datasets (27 subjects)

%ER 02/2008

warning('off','MATLAB:dispatcher:InexactCaseMatch');

clear
addpath(genpath('~/vistasoft'));
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008'));
dt6filename='dt6.mat';
load('/biac3/wandell4/users/elenary/longitudinal/subjectCodes');


%infinite loop -- finish when found 108 culled SLF groups) -- for it to
%work must have run at least one manually
while (size(findstr('MoriSymmGroups.mat', ls('/biac3/wandell4/data/reading_longitude/dti_y1234/*/dti06rt/Mori/MoriSymmGroups.mat')), 2)<108)

for subjID=1:size(subjectCodes, 2)
    cd(['/biac3/wandell4/data/reading_longitude/dti_y1234/' subjectCodes{subjID} '/dti06rt/']);


    if (~exist('Mori/MoriSymmGroupsCulled.mat', 'file') && ~exist('Mori/MoriSymmGroupsCulled.TMP', 'file')) 
   %place a flag
    save('Mori/MoriSymmGroupsCulled.TMP', 'subjID'); %flag: we are workin on it
    else continue
    end

    	%Find Mori Groups with a new (symmetrified) Atlas
	fg=dtiFindMoriTracts(dt6filename, 'Mori/MoriSymmGroups', [],'MNI_JHU_tracts_prob_Symmetric.nii.gz');
    	%load('Mori/MoriSymmGroups.mat');

    fprintf(1, subjectCodes{subjID});

%Cull
    Tt=1; distanceCrit=1.7;
    tic; fg=dtiCullFibers(fg, dt6filename, Tt, distanceCrit); toc;
    dtiWriteFiberGroup(fg, 'Mori/MoriSymmGroupsCulled'); 	
    
    unix('rm Mori/MoriSymmGroupsCulled.TMP'); %remove flag--no longer working on it
    %leave a log record
    unix(['echo ' subjectCodes{subjID} '>>/biac3/wandell4/users/elenary/longitudinal/`uname -n`MoriSymm.txt']);
    
end
end