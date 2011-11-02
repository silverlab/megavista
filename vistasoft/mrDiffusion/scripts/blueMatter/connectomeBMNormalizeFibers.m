script connectomeBMNormalizeFibers
%Split 1000K dataset into 10 subsets

cd /biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix
fgFile='/biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix/all_1000K.mat'
load(fgFile);
for fgId=1:10
fgTemp=fg;
fgTemp.fibers=fg.fibers((fgId-1)*100000+1:fgId*100000); 
fgTemp.fibers=cellfun(@double, fgTemp.fibers, 'UniformOutput', false)
dtiWriteFiberGroup(fgTemp, ['/biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix/all_100K' num2str(fgId) '.mat']); 
end
clear

% Perform Mori classification for each of 10 data subsets
for fgId=1:10
fgFile=['/biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix/all_100K' num2str(fgId) '.mat']
dt6File='/biac3/wandell5/data/Connectome/09-09-12.1_3T2/dti72/dt6.mat';
Atlas=[]; 
outFile=['/biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix/MoriGroups/all_100K' num2str(fgId) '_Mori.mat'];
saveMrDiffusion=1; 
saveQuench=1; 
showFig=1;  useJhuFa=false; useRoiBasedApproach=true; useInterhemisphericSplit=false; 
[fg, fg_unclassified]=dtiFindMoriTracts(dt6File, outFile, fgFile, Atlas, showFig, saveQuench, saveMrDiffusion, useJhuFa, useInterhemisphericSplit, useRoiBasedApproach);
dtiWriteFiberGroup(fg_unclassified, ['/biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix/MoriGroups/all_100K' num2str(fgId) '_notMori.mat']);
end


%Now aggregate across 10 subsets and run through blue matter to generalize initial solution for full brain BM
%%%%%%%%%%5
cd /biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix/MoriGroups
fgMori=dtiNewFiberGroup('all_1000kMoriGroups');
fgNotMori=dtiNewFiberGroup('all_1000kUNclassified');
for fgId=1:10
fgFile=['/biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix/MoriGroups/all_100K' num2str(fgId) '_Mori.mat']
fgM=dtiLoadFiberGroup(fgFile); 
fg_unclassifiedFile=['/biac3/wandell5/data/Connectome/09-09-12.1_3T2/mrtrix/MoriGroups/all_100K' num2str(fgId) '_notMori.mat'];
fgUC=dtiLoadFiberGroup(fg_unclassifiedFile);
 
fgMori.fibers=vertcat(fgMori.fibers, fgM.fibers); 
fgNotMori.fibers=vertcat(fgNotMori.fibers, fgUC.fibers); 
end
fgMori.params=fg.params;
fgNotMori.params=fg.params;
dtiWriteFiberGroup(fgMori, fgMori.name);
dtiWriteFiberGroup(fgNotMori, fgNotMori.name);

dtiWriteFibersPdb(fg, dt.xformToAcpc,  'all_1000kMoriGroups.pdb');

%Prepare BM files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataDir='/biac3/wandell5/data/Connectome/09-09-12.1_3T2';
g=712; b=2000; gdirs=72; 
connectomePrepareBMfiles(dataDir, g, b, gdirs);

   
%Start blue matter for Mori Groups
inputPdbMori='all_1000kMoriGroups.pdb';
outputPdbMori_DN='all_1000kMoriGroups_DN.pdb';
system(['/biac3/wandell4/users/elenary/density_normalization/scripts/runSAmpi.sh ' inputPdbMori ' ' outputPdbMori_DN ' &']); 