%Cull redundant fibers in MoriGroups 15, 16, 19, 20 (tSLF and pSLF) for 
warning('off','MATLAB:dispatcher:InexactCaseMatch');

clear
addpath(genpath('~/vistasoft'));
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008'));
dt6filename='dt6.mat';
load('/biac3/wandell4/users/elenary/longitudinal/subjectCodes');


%infinite loop -- finish when found 108 culled SLF groups) -- for it to
%work must have run at least one manually
while (size(findstr('MoriSLFGroupsCulled.mat', ls('/biac3/wandell4/data/reading_longitude/dti_y1234/*/dti06rt/Mori/MoriSLFGroupsCulled.mat')), 2)<108)

for subjID=1:size(subjectCodes, 2)
    cd(['/biac3/wandell4/data/reading_longitude/dti_y1234/' subjectCodes{subjID} '/dti06rt/']);

    if (exist('Mori/MoriGroups.mat', 'file') && ~exist('Mori/MoriSLFGroupsCulled.mat', 'file') && ~exist('Mori/MoriSLFGroupsCulled.TMP', 'file')) 
   %place a flag
    save('Mori/MoriSLFGroupsCulled.TMP', 'subjID'); %flag: we are workin on it
    load('Mori/MoriGroups.mat');
    else continue
    end

    fprintf(1, subjectCodes{subjID});
%Keep only fibers from fg 15, 16, 19, 20
    fg.name=[fg.name 'pSLF tSLF'];
    fibs_to_dismiss=find(fg.subgroup~=15 & fg.subgroup~=16 & fg.subgroup~=19 & fg.subgroup~=20);
    fg.seeds(fibs_to_dismiss, :)=[];
    fg.fibers(fibs_to_dismiss)=[];
    fg.subgroup(fibs_to_dismiss)=[];

%Cull
    Tt=1; distanceCrit=1.7;
    tic; fg=dtiCullFibers(fg, dt6filename, Tt, distanceCrit); toc;
    save('Mori/MoriSLFGroupsCulled', 'fg', 'coordinateSpace', 'versionNum'); 	

%Save CINCH-compatible
    outBase= 'Mori/MoriSLFGroupsCulled';
    % Also save a CINCH pdb file/state file to show the fiber groups.
    % Should we use dtiWriteFibersPdb?
    mtrExportFibers(fg, [outBase '.pdb']);
    % merge some of the groups to fit into the CINCH 8-group limit:
    fgInds = fg.subgroup;
    fgInds(fgInds~=15 & fgInds~=16 & fgInds~=19 &  fgInds~=20) = 0;
    fgInds(fgInds==15|fgInds==16) = 1;
    fgInds(fgInds==19|fgInds==20) = 2;
    dtiCinchSaveFibersState(fgInds, [outBase '.cst']);

    
    unix('rm Mori/MoriSLFGroupsCulled.TMP'); %remove flag--no longer working on it
    %leave a log record
    unix(['echo ' subjectCodes{subjID} '>>/biac3/wandell4/users/elenary/longitudinal/`uname -n`.txt']);
    
end
end