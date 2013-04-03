function params = rd_mrMakeMrInit2Params

% function params = rd_mrMakeMrInit2Params
%
% Makes a params structure that can be passed to mrInit2, to run it from
% the command line with specified params.
%
% Run this from the session directory. It will look for certain files in
% certain locations within that directory.
%
% Rachel Denison
% 2011 Nov 21

% ------------------------------------------------------------------------
% Setup
% ------------------------------------------------------------------------
% Here we have the most common analysis settings that are specific to an
% individual experiment
subjectID = 'MN';
description = 'MN_20120806_recon2';
comments = '';

% Scan groups
scanGroups = {[2 10], 3:9, 1}; % MN recon 2 {hemi, mp, fix}. mp has 3 variants of epi03.
% scanGroups = {[2 8], 3:7, 1}; % MN {hemi, mp, fix}
% scanGroups = {[2 11], 3:10, [1 13 12 14]}; % RD {hemi, mp, steady [fix M P fullField]}
% scanGroups = {[2 11], 3:10, 1, 12, 13}; % JN {hemi, mp, fix, M, P}
% scanGroups = {[2 11], 3:10, [1 12 13]}; % JN distortion-corrected {hemi, mp, fix, M, P}
% scanGroups = {[7 9], 1:6, 8}; % SB {hemi, mp, fix}
% scanGroups = {1:4}; % KS 1.25
% scanGroups = {[1 6], 2:5};
% scanGroups = {[1 10], 2:9};
% scanGroups = {[1 9], 2:8};
% scanGroups = {[1 16], 2:15};
% scanGroups = {[1 14], 2:13};
% scanGroups = {[1 11], 2:10}; % scan numbers in each scan group

% Keep frames
% scanGroupKeepFrames = {[32 -1], [8 270]}; % CM 3T zoom (TR=1s)
% scanGroupKeepFrames = {[5 -1], [3 90], [10, -1]}; % RD 7T Aug (TR=3s)
% scanGroupKeepFrames = {[8 128], [4 135], [16 -1], [16 -1], [16 -1]}; % JN 
% scanGroupKeepFrames = {[8 128], [4 135], [16 -1]}; % JN distortion-corrected
scanGroupKeepFrames = {[8 128], [4 135], [16 -1]}; % SB, MN 
% scanGroupKeepFrames = {[8 128], [4 135], [0 180]}; % SB distortion-corrected (only thowing away the final frame (the response))
% scanGroupKeepFrames = {[4 135]}; % KS 1.25
% scanGroupKeepFrames = {[16 -1], [4 135]}; % 7T
% scanGroupKeepFrames = {[6 132], [4 -1]}; % 3T [frames-to-discard frames-to-keep]

% Annotations
% scanGroupNames = {'mp'}; % KS 1.25
% scanGroupNames = {'hemi','mp','fix','M','P'};
% scanGroupNames = {'hemi','mp','steady'};
scanGroupNames = {'hemi','mp','fix'};
% scanGroupNames = {'hemi','mp'};

% Parfiles
% scansWithParfile = 1:4; % KS 1.25
scansWithParfile = scanGroups{2};

% Coherence analysis
% coherenceScanGroups = 0; % KS 1.25
coherenceScanGroups = 1;
nCycles = 8; % 7T, CM 3T zoom
% nCycles = 11; % 3T

% GLM analysis
% glmScanGroups = 1; % KS 1.25
glmScanGroups = 2;
% eventsPerBlock = 16; % CM
% eventsPerBlock = 5; % RD
eventsPerBlock = 8; % length of block in TRs
snrConds = 1:2; % conditions used to calculate SNR (0 is baseline)

% ------------------------------------------------------------------------
% Files
% ------------------------------------------------------------------------
[p f ext] = fileparts(pwd);
fprintf('\nMaking params for %s...', description)
fprintf('\nCurrent path is %s/%s\n\n', p, f)

% Expect to find data in a file named SESSIONNAME_nifti
niftiDir = [f '_nifti'];

inplaneFile = dir([niftiDir '/gems*.nii.gz']);
inplane = sprintf('%s/%s/%s/%s', p, f, niftiDir, inplaneFile.name);

functionalFiles = dir([niftiDir '/*mcf.nii.gz']); % /*mcf.nii.gz, /*fsldc.nii.gz
for iFunc = 1:numel(functionalFiles)
    functionals{iFunc,1} = sprintf('%s/%s/%s/%s', ...
        p, f, niftiDir, functionalFiles(iFunc).name);
end

% vAnatomy = sprintf('%s/%s/Anatomicals/vAnatomy.dat', p, f);
% vAnatomy = sprintf('%s/%s/Anatomicals/ot1mpr.nii.gz', p, f);
vAnatomy =  sprintf('/Volumes/Plata1/Anatomies/Anatomicals/%s/vAnatomy.dat', subjectID);

% Expect to find parfiles in the specified directory
parfileDir = 'Stimuli/parfiles';
parfileFiles = dir([parfileDir '/*.par']);
for iPar = 1:numel(parfileFiles)
    parfiles{iPar} = parfileFiles(iPar).name;
end

% ------------------------------------------------------------------------
% Analysis params
% ------------------------------------------------------------------------
% Coherence analysis
co = coParamsDefault;
co.nCycles = nCycles;

% GLM analysis
glm = er_defaultParams;
glm.snrConds = snrConds;
glm.eventsPerBlock = eventsPerBlock;
% glm.detrendFrames = 40; % CM only! otherwise leave as default

% ------------------------------------------------------------------------
% Scan groups
% ------------------------------------------------------------------------
for iGroup = 1:numel(scanGroups)
    scans = scanGroups{iGroup};
    for iScan = 1:numel(scans)
        scan = scans(iScan);
        keepFrames(scan,:) = scanGroupKeepFrames{iGroup};
        annotations{scan,1} = sprintf('%s %d', scanGroupNames{iGroup}, iScan);
        
        if any(iGroup==coherenceScanGroups)
            coParams{1,scan} = co;
        else
            coParams{1,scan} = [];
        end
        if any(iGroup==glmScanGroups)
            glmParams{1,scan} = glm;
        end
    end
end

% ------------------------------------------------------------------------
% Parfile assignments
% ------------------------------------------------------------------------
parfile = cell(1,numel(functionals));
for iScan = 1:numel(scansWithParfile)
    scan = scansWithParfile(iScan);
    parfile{scan} = parfiles{iScan};
end

% ------------------------------------------------------------------------
% Create params
% ------------------------------------------------------------------------
% Note several defaults are set here
params.inplane = inplane;
params.functionals = functionals;
params.vAnatomy = vAnatomy;
params.sessionDir = pwd;
params.sessionCode = f;
params.subject = subjectID;
params.description = description;
params.comments = comments;
params.crop = [];
params.keepFrames = keepFrames;
params.annotations = annotations;
params.parfile = parfile;
params.coParams = coParams;
params.glmParams = glmParams;
params.scanGroups = scanGroups;
params.applyGlm = 0;
params.applyCorAnal = [];
params.motionComp = 0;
params.sliceTimingCorrection = 0;
params.motionCompRefScan = 1;
params.motionCompRefFrame = 1;
params.doDescription = 1;
params.doCrop = 0;
params.doAnalParams = 1;
params.doPreprocessing = 0;
params.doSkipFrames = 1;
params.startTime = datestr(now);
