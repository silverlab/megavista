function connectomePrepareBMfiles(dataDir, g, b, gdirs)
%Prepare files for running blue matter
%
%  connectomePrepareBMfiles(dataDir, g, b, gdirs)
%
% Example: 
%     dataDir='/biac3/wandell5/data/Connectome/09-09-12.1_3T2/' g=712;
%     b=2000;  gdirs=72; connectomePrepareBMfiles(dataDir, g, b, gdirs)

cd(dataDir);
dt6Dir=fullfile(dataDir, ['dti' num2str(gdirs)]);
dtiRawDir=fullfile(dataDir, 'raw');
dtiRawAverage(fullfile(dtiRawDir, ['dti_g' num2str(g) '_b' num2str(b) '_aligned_trilin.nii.gz']),fullfile(dtiRawDir, ['dti_g' num2str(g) '_b' num2str(b) '_aligned_trilin.bvecs']), fullfile(dtiRawDir, ['dti_g' num2str(g) '_b' num2str(b) '_aligned_trilin.bvals']));
dtiMakeBrainMaskSafe(dt6Dir, fullfile(dtiRawDir, ['dti_g' num2str(g) '_b' num2str(b) '_aligned_trilin_avg.nii.gz']));
dt6File=fullfile(dt6Dir, 'dt6.mat');
spName=fullfile('fibers', 'conTrack', 'ctr_paramsDN.txt');
p.dt6File=dt6File; p.roiMaskFile='brainMask.nii.gz';
p.timeStamp=datestr(now,30);p.roi1File=[]; p.roi2File=[]; p.wm=false;p.pddpdf=true;p.dSamples=300;p.maxNodes=300;p.minNodes=10; p.stepSize=1;
p = ctrInitParamsFile(p, spName);  %saved in root/fibers/conTrack and refers to image directory dti06/bin/ (with pdf and the brain mask)