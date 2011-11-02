%Script that culls away redundant fibers in Mori-labeled fiber groups
clear
addpath(genpath('~/vistasoft'));
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008'));
dt6filename='dt6.mat';
cd /biac3/wandell4/data/reading_longitude/dti_y1234
all_subjects=dir; 

for dirI=3:size(all_subjects, 1)

subject_dirname=all_subjects(dirI).name;
    
    if (isdir(subject_dirname)&& ~strcmp(subject_dirname, '.') && ~strcmp(subject_dirname, '..'))
    display(subject_dirname)
    cd([subject_dirname filesep 'dti06rt']);

    load('fibers/MoriGroups.mat');
    Tt=1; distanceCrit=1.7;
    tic; fg=dtiCullFibers(fg, dt6filename, Tt, distanceCrit); toc;
    save('fibers/MoriGroupsCulled', 'fg', 'coordinateSpace', 'versionNum'); 	

    outBase= 'fibers/MoriGroupsCulled';
    % Also save a CINCH pdb file/state file to show the fiber groups.
    % Should we use dtiWriteFibersPdb?
    mtrExportFibers(fg, [outBase '.pdb']);
    % merge some of the groups to fit into the CINCH 8-group limit:
    fgInds = fg.subgroup;
    fgInds(fgInds==2) = 1;
    fgInds(fgInds==3|fgInds==4) = 2;
    fgInds(fgInds==5|fgInds==6|fgInds==7|fgInds==8) = 3;
    fgInds(fgInds==9|fgInds==10) = 4;
    fgInds(fgInds==11|fgInds==12|fgInds==13|fgInds==14) = 5;
    fgInds(fgInds==15|fgInds==16) = 6;
    fgInds(fgInds==17|fgInds==18) = 7;
    fgInds(fgInds>18) = 0;
    dtiCinchSaveFibersState(fgInds, [outBase '.cst']);

    
    cd ('/biac3/wandell4/data/reading_longitude/dti_y1234'); 
    end
end

return

%Evaluate the results: pre-and post-cull fiber counts
cd /biac3/wandell4/data/reading_longitude/dti_y1234
all_subjects=strread(ls('*/dti06rt/fibers/MoriGroupsCulled.mat'), '%s'); 

fprintf(['Subjects total: ' num2str(size(all_subjects, 1)) '\n']);
fprintf('Processing: ');

for subject=1:size(all_subjects, 1)
   
    fprintf([num2str(subject) ' ']);
    load(char(all_subjects(subject, :))); 
    postcullsize(subject)=size(fg.seeds, 1);    
    load([fileparts(char(all_subjects(subject, :))) '/MoriGroups.mat']); 

    precullsize(subject)=size(fg.seeds, 1);
end


