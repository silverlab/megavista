addpath(genpath('~/vistasoft'));
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008/'));


%load('/biac3/wandell4/users/elenary/longitudinal/subjectCodes');
load('/biac3/wandell4/users/elenary/longitudinal/subjectCodesAll4Years');
subjectID=subjectCodes;
project_folder='/biac3/wandell4/data/reading_longitude/dti_y1234/';

%%%%%%%
%Compute MoriGroups.mat & MoriGroupsConnectingGM
%%%%%%%%%%
for s=1:size(subjectID, 2); 
subjectID{s}
cd(fullfile(project_folder, subjectID{s}, 'dti06trilinrt', 'fibers'));
    
%1. Given allConnectingGM_MoriGroups.pdb, create a respective CST file
fg=dtiLoadFiberGroup('allConnectingGM_MoriGroups.mat');
dtiQuenchSaveFibersState(fg.subgroup, 'allConnectingGM_MoriGroups.cst');

%2. allConnectingGM_MoriGroups_DN.pdb, create a respective CST
dtiSubgroupToCinch('allConnectingGM_MoriGroups.mat', 'allConnectingGM_MoriGroups_DN_andOther.cst', 'allConnectingGM_MoriGroups_DN.ind', 0)

%3.  allConnectingGM.mat: first N fibers are Mori ones, then the extras are
%unclassified. Use that knowledge. 
fgAll=dtiLoadFiberGroup('allConnectingGM.mat'); 
numFiberAll=size(fgAll.fibers); 
fg=dtiLoadFiberGroup('allConnectingGM_MoriGroups.mat'); 
fgAll.subgroup=zeros(numFiberAll); 
fgAll.subgroup(1:length(fg.subgroup))=fg.subgroup; clear fg;
dtiSubgroupToCinch(fgAll, 'allConnectingGM_MoriAndNonMori.cst', [], 1)

%4.  allConnectingGM_DN.mat: Mori Labels for the indices correspoinding to
%first N fibers can be obtained from allConnectingGM_MoriGroups, the rest
%should be "0"; 

end
