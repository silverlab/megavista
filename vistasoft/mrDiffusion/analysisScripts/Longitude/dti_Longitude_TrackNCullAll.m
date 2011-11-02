%Script that culls away redundant fibers in Mori-labeled fiber groups
clear
addpath(genpath('~/vistasoft'));
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008'));
dt6filename='dt6.mat';
cd /biac3/wandell4/data/reading_longitude/dti_y1234
all_subjects=dir; 
dt6File='dt6.mat'; allOutBase='all'; Tt=1; distanceCrit=1.7;

for dirI=3:size(all_subjects, 1)

subject_dirname=all_subjects(dirI).name;
    
    if (isdir(subject_dirname)&& ~strcmp(subject_dirname, '.') && ~strcmp(subject_dirname, '..'))
    display(subject_dirname)
    cd([subject_dirname filesep 'dti06rt']);

%Perform full brain tractography
dt = dtiLoadDt6(dt6File);

    % Track all white matter fibers in the native subject space. We do this by
    % seeding all voxels with high FA (>0.3).
    faThresh = 0.30;
    opts.stepSizeMm = 1;
    opts.faThresh = 0.15;
    opts.lengthThreshMm = [50 250];
    opts.angleThresh = 50;
    opts.wPuncture = 0.2;
    opts.whichAlgorithm = 1;
    opts.whichInterp = 1;
    opts.seedVoxelOffsets = [0.25 0.75];
    opts.offsetJitter = 0.1;
    fa = dtiComputeFA(dt.dt6);
    fa(fa>1) = 1; fa(fa<0) = 0;
    roiAll = dtiNewRoi('all');
    mask = dtiCleanImageMask(fa>=faThresh);
    [x,y,z] = ind2sub(size(mask), find(mask));
    clear mask fa;
    roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);
    clear x y z;
    fg = dtiFiberTrack(dt.dt6, roiAll.coords, dt.mmPerVoxel, dt.xformToAcpc, 'FG', opts);
    clear roiAll

    % Save in mrDiffusion format:
    dtiWriteFiberGroup(fg, ['fibers' filesep allOutBase '.mat']);

%Cull
    tic; fg=dtiCullFibers(fg, dt6File, Tt, distanceCrit); toc;
    % Save in mrDiffusion format:
    dtiWriteFiberGroup(fg, ['fibers' filesep allOutBase '_Culled.mat']);
    
    cd ('/biac3/wandell4/data/reading_longitude/dti_y1234'); 
    end
end

return

%Evaluate the results: pre-and post-cull fiber counts
cd /biac3/wandell4/data/reading_longitude/dti_y1234
%all_subjects=strread(ls('*/dti06rt/fibers/MoriGroupsCulled.mat'), '%s'); 
all_subjects=strread(ls('*/dti06rt/fibers/all.mat'), '%s'); 

fprintf(['Subjects total: ' num2str(size(all_subjects, 1)) '\n']);
fprintf('Processing: ');

for subject=1:size(all_subjects, 1)
   
    fprintf([num2str(subject) ' ']);
    load(char(all_subjects(subject, :))); 
    postcullsize(subject)=size(fg.seeds, 1);    
 %   load([fileparts(char(all_subjects(subject, :))) '/MoriGroups.mat']); 
    load([fileparts(char(all_subjects(subject, :))) '/all.mat']); 
    precullsize(subject)=size(fg.seeds, 1);
end