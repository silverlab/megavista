function [fgSTT, fgTrackVis] = bmCreatePDBs(subjectDir)
%Create PDBs for subject 
%
%   
%
% AUTHORS:
% 2009.09.05 : AJS wrote it.
%
% NOTES: 

% Directories
binDir = bmGetName('binDir',subjectDir);
fiberDir = bmGetName('fiberDir',subjectDir);
roiDir = bmGetName('roiDir',subjectDir);
% Input Files
volExFile = bmGetName('volExFile',subjectDir);
wmROIFile = bmGetName('wmROIFile',subjectDir);
gmROIFile = bmGetName('gmROIFile',subjectDir);
% Output Files
ctrparamsFile = bmGetName('ctrparamsFile',subjectDir);
stt_trkPDBFile = bmGetName('stt_trkPDBFile',subjectDir);

% Validate existence of directories
if ~exist(wmROIFile,'file') || ~exist(gmROIFile,'file')
    error('WM or GM file do not exist, must provide a valid subject path!');
end
% Create fiber directory
if ~isdir(fiberDir); mkdir(fiberDir); end
% Create ROI directory
if ~isdir(roiDir); mkdir(roiDir); end

disp(' '); disp('Creating ConTrack parameters file for STT and ConTrack ...');
% Global Tracking Parameters
[foo, wmFile, ext] = fileparts(wmROIFile);
wmFile = [wmFile ext];
[foo, roiFile, ext] = fileparts(gmROIFile);
roiFile = [roiFile ext];
pdfFile = 'pdf.nii.gz';
nMinNodes = 5;
nMaxNodes = 300;
vol = readFileNifti(volExFile);
fStepSizeMm = min(vol.pixdim)/2;
nfgWriteConTrackParams(ctrparamsFile, binDir, wmFile, roiFile, pdfFile, nMinNodes, nMaxNodes, fStepSizeMm);

fgSTT = [];
fgTrackVis = [];

disp(' '); disp('Creating STT projectome with mrDiffusion ...');
fgSTT = bmCreateSTTPDB(subjectDir, fStepSizeMm, nMinNodes, nMaxNodes);

disp(' '); disp('Creating TEND projectome with mrDiffusion ...');
%bmCreateTENDPDB(subjectDir, fStepSizeMm, nMinNodes, nMaxNodes);

disp(' '); disp('Creating HARDI projectome with mrDiffusion ...');
%fgTrackVis = bmCreateTrackvisPDB(subjectDir,1);

%% Create a combined HARDI STT file 
%fgBoth = fgS;
%fgBoth.fibers(end+1:end+length(fgT.fibers)) = fgT.fibers;
%fgBoth = dtiClearQuenchStats(fgBoth);
%fgBoth = dtiCreateQuenchStats(fgBoth,'Length','Length', 1);
%fgBoth = dtiCreateQuenchStats(fgBoth,'Group',[zeros(1,length(fgS.fibers)) ones(1,length(fgT.fibers))]);
%mtrExportFibers(fgBoth,stt_trkPDBFile);

disp('Done.');
return;