function [fg] = bmCreateTENDPDB(subjectDir, fStepSizeMm, nMinNodes, nMaxNodes)
%Create TEND PDB using mrDiffusion
%
%   [fg] = bmCreateTENDPDB(subjectDir, fStepSizeMm, nMinNodes, nMaxNodes,
%   bSanityCheck)
%
% AUTHORS:
% 2009.09.05 : AJS wrote it.
%
% NOTES: 

% Directories
% Input Files
dtFile = bmGetName('dtFile',subjectDir);
wmROIFile = bmGetName('wmROIFile',subjectDir);
% Output Files
tendPDBFile = bmGetName('tendPDBFile',subjectDir);
ctrparamsFile = bmGetName('ctrparamsFile',subjectDir);

% Tracking Parameters
faThresh = 0.15;
opts.stepSizeMm = fStepSizeMm;
opts.faThresh = faThresh;
opts.lengthThreshMm = [nMinNodes-1 nMaxNodes-1]*fStepSizeMm;
opts.angleThresh = 90;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 3;
opts.whichInterp = 1;
opts.seedVoxelOffsets = 0.5;

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
disp('Tracking TEND fibers ...');
fg = dtiFiberTrack(dt.dt6,roiAll.coords,dt.mmPerVoxel,dt.xformToAcpc,'FG_TEND',opts);
fg = dtiClearQuenchStats(fg);
%fgSTT = dtiCreateQuenchStats(fgSTT,'Length','Length', 1);
mtrExportFibers(fg, tendPDBFile);
disp(['The TEND fiber group has been written to ' tendPDBFile]);

% Call contrack_score to limit fibers to those intersecting the GM ROI
disp('Removing fibers that do not have both endpoints in GM ROI ...');
pParamFile = [' -i ' ctrparamsFile];
pOutFile = [' -p ' tendPDBFile];
pInFile = [' ' tendPDBFile];
pThresh = [' --thresh ' num2str(length(fg.fibers))];
cmd = ['contrack_score' pParamFile pOutFile pThresh ' --find_ends' pInFile];
disp(cmd);
system(cmd,'-echo');
fg = mtrImportFibers(tendPDBFile);

return;