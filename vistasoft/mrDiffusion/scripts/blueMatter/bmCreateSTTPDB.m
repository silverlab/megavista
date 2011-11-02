function [fg] = bmCreateSTTPDB(subjectDir, fStepSizeMm, nMinNodes, nMaxNodes, bSanityCheck)
%Create STT PDB using mrDiffusion
%
%   [fg] = nfgCreateSTTPDB(subjectDir, fStepSizeMm, nMinNodes, nMaxNodes,
%   bSanityCheck)
%
% AUTHORS:
% 2009.09.05 : AJS wrote it.
%
% NOTES: 

if ieNotDefined('bSanityCheck'); bSanityCheck=0; end

% Directories
% Input Files
dtFile = bmGetName('dtFile',subjectDir);
wmROIFile = bmGetName('wmROIFile',subjectDir);
% Output Files
sttPDBFile = bmGetName('sttPDBFile',subjectDir);
ctrparamsFile = bmGetName('ctrparamsFile',subjectDir);

% Tracking Parameters
faThresh = 0.1;
opts.stepSizeMm = fStepSizeMm;
opts.faThresh = faThresh;
opts.lengthThreshMm = [nMinNodes-1 nMaxNodes-1]*fStepSizeMm;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.0]; %[-0.25 0.25];

% Create ROI from WM mask that has high enough FA
disp(['Creating WM ROI with FA > ' num2str(faThresh) ' ...']);
wm = readFileNifti(wmROIFile);
dt = dtiLoadDt6(dtFile);
fa = dtiComputeFA(dt.dt6);
fa(fa>1) = 1; fa(fa<0) = 0;
roiAll = dtiNewRoi('all');
mask = wm.data>0 & fa>=faThresh;
[x,y,z] = ind2sub(size(mask), find(mask));
roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);

% Track Fibers
disp('Tracking STT fibers ...');
fg = dtiFiberTrack(dt.dt6,roiAll.coords,dt.mmPerVoxel,dt.xformToAcpc,'FG_STT',opts);
fg = dtiClearQuenchStats(fg);
%fgSTT = dtiCreateQuenchStats(fgSTT,'Length','Length', 1);
mtrExportFibers(fg, sttPDBFile);
disp(['The STT fiber group has been written to ' sttPDBFile]);

% Call contrack_score to clip fibers to the ROI and also remove fibers that
% don't make it to the ROI
disp('Removing fibers that do not have both endpoints in GM ROI ...');
pParamFile = [' -i ' ctrparamsFile];
pOutFile = [' -p ' sttPDBFile];
pInFile = [' ' sttPDBFile];
pThresh = [' --thresh ' num2str(length(fg.fibers))];
cmd = ['contrack_score' pParamFile pOutFile pThresh ' --find_ends' pInFile];
disp(cmd);
system(cmd,'-echo');

fg = mtrImportFibers(sttPDBFile);

if bSanityCheck
% NFG Sanity Check would not work because it uses gold fibers
end

return;