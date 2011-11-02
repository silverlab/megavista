function [outputPdb_DN]=connectomeTestContrackPathwaysWithBlueMatter(BMsolutionPdb, ContrackFibersPdb, dt6Dir, outputDir, outputPdbPrefix, g, b)

%[outputPdfPrefix]=connectomeTestContrackPathwaysWithBlueMatter(BMsolutionPdb, ContrackFibersPdb, dt6Dir, [outputDir], [outputPdbPrefix], [g], [b])

%Test a contrack-generated group of pathways against a finalized blue matter solution. 
%Will create files <outputPdfPrefix>.pdb and  <outputPdfPrefix>_DN.pdb/<outputPdfPrefix>.ind in the outputDdir.

%Important: set your g and b properly (as they are in the filenames of the relevant dti files), the default values are for the connectome projet HARDI data. 

%%BM solution are indices of fibers to keep--in the space of combined contrackFibers+BMsolution (saved as outputPdfPrefix). PLUS1!!! (those indices count from 0)
%To look at which fibers from the contrack set survive the BM test, import your .ind file and your winners are  fgTest.fibers(ind+1).

%ER wrote it 11/2009

if ~exist('g', 'var')|| isempty(g)
    g=150; %For connectome project
end

if ~exist('g', 'var')|| isempty(g)
    b=2500; %For connectome project
end

if ~exist('outputPdbPrefix', 'var') || isempty(outputPdbPrefix)
    [pathstrBM, fileBM, extBM]=fileparts(BMsolutionPdb);
    [pathstrCtr, fileCtr, extCtr]=fileparts(ContrackFibersPdb);
    outputPdbPrefix=[fileCtr 'plus' fileBM]; 
end
if strmatch(outputPdbPrefix(end-3:end), '.pdb')
   outputPdbPrefix=outputPdbPrefix(1:end-4);%PDB file to save the merged Hyp fibers and BM solution -- and then test. 
end

 
dt6File=fullfile(dt6Dir, 'dt6.mat');
dt=dtiLoadDt6(dt6File); 

[fgBM] = mtrImportFibers(BMsolutionPdb); 
[fgTest] = mtrImportFibers(ContrackFibersPdb);
fgBoth=dtiMergeFiberGroups(fgTest, fgBM); 
dtiWriteFibersPdb(fgBoth,dt.xformToAcpc, fullfile( outputDir, [ outputPdbPrefix '.pdb'])); 

display([num2str(length(fgTest.fibers)) ' fibers in the tested FG']);  

%3. Start blue matter
inputPdb= fullfile(outputDir, [outputPdbPrefix '.pdb']);
outputPdb_DN= [inputPdb(1:end-4) '.pdb'];
system(['/biac3/wandell4/users/elenary/Connectome/scripts/truSAcommands.sh ' dt6Dir ' ' inputPdb ' ' outputPdb_DN ' ' num2str(g) ' ' num2str(b) ' &']);
 
return

subjids={'ws090930', 'rb090930'}; subj=2; %WORKING ON RENO

%Current blue matter solution
BMsolutionPdb=fullfile('/biac3/wandell5/data/Connectome/', subjids{subj}, '/mrtrix/all_stt_200K_ConnectingGM_DN.pdb');
%Directory with dt6 file
dt6Dir=fullfile('/biac3/wandell5/data/Connectome/', subjids{subj}, 'dti150'); 
g=150; b=2500; 
outputDir=fullfile('/biac3/wandell5/data/Connectome/', subjids{subj}, '/fibers/conTrackBMCheck'); 
system(['mkdir -p ' outputDir]); 

%Pathways to test: %3->5 and 3-> 6 for WS; 5->6&5->7 for Reno
ContrackFibersPdb=fullfile('/biac3/wandell5/data/Connectome/', subjids{subj}, '/fibers/conTrack/salienceThreeBlobs_and_DMNFourBlobs_blobs5000_7000.pdb');
outputPdbPrefix='DMN_blobs5000_7000_Plus_all_stt_200K_ConnectingGM_DN.pdb'; %Also looked at 3000 to 6000 for WS

[outputPdbMori_DN]=connectomeTestContrackPathwaysWithBlueMatter(BMsolutionPdb, ContrackFibersPdb, dt6Dir, outputDir, outputPdbPrefix, g, b);
