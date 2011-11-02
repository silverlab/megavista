% dti_FFA_mtrClipFG
%
% Usage: dti_FFA_mtrClipFG
%
% Wrapper script for
% mtrClipFiberGroupToROIs(fgin,t1,roi1,roi2,wm,fgout)
%
% DY 09/2008

% Start in subject's dti30 directory
clear all
subDir=pwd
theroi1='RFFA_MBvACIO_p3ddilate8.mat';
theroi2='RPPA_IOvACMB_p3ddilate8.mat';
thefg1='RFFAep_RPPAnoep_p3ddilate8.mat';
thefg2='RPPAep_RFFAnoep_p3ddilate8.mat';
% theroi1='_dilate8.mat';
% theroi2='RPPA_IOvACMB_dilate8.mat';
% theroi2='RLOf_MBvACIO_p3ddilate8.mat';
% theroi1='RFFA_MBvACIO_p3ddilate8.mat';
% theroi1='RRSC_IOvACMB_p3ddilate8.mat';
% theroi2='Rdplc_IOvACMB_p3ddilate8.mat';
% wm=fullfile(binDir,'wmMask.nii.gz'); % causes mtrClip to crash for some
% reason. 

% Set stereotyped relative paths
fiberDir=fullfile(subDir,'fibers','functional');
roiDir=fullfile(subDir,'ROIs','functional');
t1Dir=fullfile(mrvDirup(subDir),'t1');
binDir=fullfile(subDir,'bin');

% Run mtrClip for FG1
fgin=fullfile(fiberDir,thefg1);

% Are there any fibers in this group?
fg=load(fgin);
fg.fg % print params to screen

t1=fullfile(t1Dir,'t1.nii.gz');
roi1=fullfile(roiDir,theroi1);
roi2=fullfile(roiDir,theroi2);
fgout=fullfile(fiberDir,[thefg1(1:end-14) 'clip.mat']);
clip1=mtrClipFiberGroupToROIs(fgin,t1,roi1,roi2,[],fgout);
clear fgin t1 roi1  roi2 fgout



% Run mtrClip for FG2
fgin=fullfile(fiberDir,thefg2);

% Are there any fibers in this group?
fg=load(fgin);
fg.fg % print params to screen

t1=fullfile(t1Dir,'t1.nii.gz');
roi1=fullfile(roiDir,theroi1);
roi2=fullfile(roiDir,theroi2);
wm=fullfile(binDir,'wmMask.nii.gz');
fgout=fullfile(fiberDir,[thefg2(1:end-14) 'clip.mat']);
clip2=mtrClipFiberGroupToROIs(fgin,t1,roi1,roi2,[],fgout);
clear fgin t1 roi1  roi2 fgout

% Write merged FG
mergeName=[thefg1(1:end-14) 'clip_merge.mat'];
mergedFG = clip1; % let the mergedFG inherit the properties (color, etc) of clip1
mergedFG.fibers=[clip1.fibers,clip2.fibers];
mergedFG.name=mergeName;
dtiWriteFiberGroup(mergedFG, fullfile(fiberDir, mergeName));

clx