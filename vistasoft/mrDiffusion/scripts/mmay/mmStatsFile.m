% This is how we created the MM stats file for the optic radiation.
%
% We mounted the \biac3\wandell4\ onto the Z: drive
% We ran this code to produce the summary statistics file.
%
% The control group was created using the same procedure (see below).

clear pathFiles;
clear subjDirs; subjDirs{1} = 'mm040325_newPreprocPipeLine';
wDir = 'Z:/data/DTI_Blind';
pathFiles(1,1) = {'ltLGN_ltV1_mm_top5000_clean.mat'}; 
pathFiles(2,1) = {'rtLGN_rtV1_mm_top5000_clean.mat'};
statsFile = 'mmORStatsAll.mat';

% Note that we created a single eigenvalue contribution from a voxel, we
% did not create multiple representations just because there are multiple
% fibers through a voxel.
eigSampling = 'allEig';  % Alternative is allEig/uniqueEig
stats = ctrCompStatsORBundles(wDir,statsFile,subjDirs,pathFiles,eigSampling);

disp('The MM statsFile is created.  ')
disp('On brian computer Move it to the 2008 Michael May (Netta) directory inside of Matlab\publications');


%%  Create the merged fibers for all the subjects in the or_clean directory
% This assumes that Y: is mounted as \White\teal, or change to
% chdir('/teal/scr1/dti/or')
% chdir('Y:\dti\or')
for ii = 1:length(subjDirs)
    fprintf('Working on %s \n',subjDirs{ii});
    chdir(fullfile('Y:\dti\or\',subjDirs{ii},'\fibers\conTrack\or_clean'))
    fg1 = dtiReadFibers('LOR_central_final');
    fg2 = dtiReadFibers('LOR_direct_final');
    fg3 = dtiReadFibers('LOR_meyer_final');
    fg = dtiMergeFiberGroups(fg1,fg2,'centralDirect');
    fg = dtiMergeFiberGroups(fg,fg3,'mergedLOR');
    dtiWriteFiberGroup(fg,'LOR_merged.mat');

    fg1 = dtiReadFibers('ROR_central_final');
    fg2 = dtiReadFibers('ROR_direct_final');
    fg3 = dtiReadFibers('ROR_meyer_final');
    fg = dtiMergeFiberGroups(fg1,fg2,'centralDirect');
    fg = dtiMergeFiberGroups(fg,fg3,'mergedROR');
    dtiWriteFiberGroup(fg,'ROR_merged.mat');
end

%% Control group optic radiation calculation
% 
%   From Windows  I mounted: \White\teal onto Y: and then change to 
% chdir('Y:\dti\or')
% chdir('/teal/scr1/dti/or')
%
% This ran OK on teal but it ran out of memory on my laptop.  I think a
% couple of the subjects (dla) have too many fibers
subjDirs = {'aab050307', 'ah051003', 'as050307', 'db061209', 'dla050311','gm050308', 'jy060309', 'me050126'};
pathFiles      = {'LOR_merged.mat'};
pathFiles(2,:) = {'ROR_merged.mat'};
wDir = pwd; statsFile = 'controlORStatsAll.mat';
eigSampling = 'allEig';  % Alternative is allEig/uniqueEig
stats = ctrCompStatsORBundles(wDir,statsFile,subjDirs,pathFiles,eigSampling);

%%  Obsolete: Control group optic radiation calculation
%  Originally we ran the calculations separately for each of the subjects.
%  In Nov 11 2008 we merged, making this part old code.
%
% I mounted: \White\teal onto Y: and then change to 
chdir('Y:\dti\or')
subjDirs = {'aab050307', 'ah051003', 'as050307', 'db061209', 'dla050311','gm050308', 'jy060309', 'me050126'};
pathFiles = {'LOR_meyer_final.mat','LOR_central_final.mat','LOR_direct_final.mat'};
pathFiles(2,:) = {'ROR_meyer_final.mat','ROR_central_final.mat','ROR_direct_final.mat'};
wDir = pwd; statsFile = 'controlORStatsAll.mat';
eigSampling = 'allEig';  % Alternative is allEig/uniqueEig
stats = ctrCompStatsORBundles(wDir,statsFile,subjDirs,pathFiles,eigSampling);
