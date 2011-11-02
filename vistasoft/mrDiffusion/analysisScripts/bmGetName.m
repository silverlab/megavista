function value = bmGetName(name,subjectDir,numGrads)
%Get standard names for BlueMatter 
%
%   value = bmGetName(name)
%
% Mostly stores directory and file names.
%
% AUTHORS:
%   2009.09.05 : AJS wrote it
%
% NOTES: 

% Suppress variable may not be used warning
%#ok<*NASGU>

% Hard Coded because this function essentially acts like a script
raw_rootName = 'dti_g150_b2500_aligned_trilin';
tissue_maskName = 't1_class_occ.nii.gz';


if ieNotDefined('numGrads'); numGrads = 30; end;

% Directories
rawDir = fullfile(subjectDir,'raw');
t1Dir = fullfile(subjectDir,'t1');
dtDir = sprintf('dti%02d',numGrads);
dtDir = fullfile(subjectDir,dtDir);
binDir = fullfile(dtDir,'bin');
fiberDir = fullfile(dtDir,'fibers','bluematter');
trkDir = fullfile(fiberDir,'trackvis');
roiDir = fullfile(dtDir,'ROIs');
% Raw Image Files
% Post-processed Image Files
brainMaskFile = fullfile(dtDir,'bin','brainMask.nii.gz');
volExFile = fullfile(binDir,'b0.nii.gz');
b0File = fullfile(binDir,'b0.nii.gz');
tensorsFile = fullfile(binDir,'tensors.nii.gz');
% Imaging Sequence Files
bvalsFile = fullfile(rawDir,raw_rootName,'.bvals');
bvecsFile = fullfile(rawDir,raw_rootName,'.bvecs');
rawFile = fullfile(rawDir,raw_rootName,'.nii.gz');
% ROIs
gmROIFile = fullfile(binDir,'gm.nii.gz');
wmROIFile = fullfile(binDir,'wm.nii.gz');
wmTrkROIFile = fullfile(binDir,'wmTrk.nii.gz');
% Tracking Files
ctrparamsFile = fullfile(fiberDir,'ctr_params.txt');
bmScriptFile = ['runBM_' subjectDir '.sh'];
bmLogFile = ['logBM_' subjectDir '.txt'];
% mrDiffusion Files
dtFile = fullfile(dtDir, 'dt6.mat');
% TrackVis Files
trkGradFile = fullfile(trkDir,'grad.txt');
trkImg = fullfile(trkDir,'dwi-trk.nii.gz');
trkHardiMatFile = fullfile(trkDir,'recon_mat.dat');
trkOdfReconRoot = fullfile(trkDir,'recon_out');
trkTRKFile = fullfile(trkDir,'tracks.trk');
trkPDBFile = fullfile(fiberDir,'trk.pdb');
trkBMPDBFile = fullfile(fiberDir,'trk_bm.pdb');
trkECullPDBFile = fullfile(fiberDir,'trk_ecull.pdb');
trkPidsDir = fullfile(fiberDir,'pids_trk');
% Fiber Names and Directories
% TEND
tendPDBFile = fullfile(fiberDir,'tend.pdb');
tendBMPDBFile = fullfile(fiberDir,'tend_bm.pdb');
% STT
sttPDBFile = fullfile(fiberDir,'stt.pdb');
sttBMPDBFile = fullfile(fiberDir,'stt_bm.pdb');
sttECullPDBFile = fullfile(fiberDir,'stt_ecull.pdb');
sttBMBfloatFile = fullfile(fiberDir,'stt_bm.Bfloat');
sttPidsDir = fullfile(fiberDir,'pids_stt');
% CTR
ctrPidsDir = fullfile(fiberDir,'pids_ctr');
ctrBMPDBFile = fullfile(fiberDir,'ctr_bm.pdb');
% Misc
bashExe = '/bin/bash';
stt_trkPDBFile = fullfile(fiberDir,'stt_trk.pdb');
tissue_maskFile = fullfile(t1Dir,tissue_maskName);

if ~ischar(name)
    error('Error: nfgGetName accepts string inputs only!');
end
if ~isvarname(name)
    error(['Error: ' name ' is not a valid variable name!']);
end

value = eval(name);

return;