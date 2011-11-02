%Perform segmentation to evaluate  brain (and, in particular, white matter) changes
%ER wrote for longitudinal data

clear
addpath(genpath('~/vistasoft'));
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008'));
load('/biac3/wandell4/users/elenary/longitudinal/subjectCodes');

for subjID=1:size(subjectCodes, 2)
    t1filename=['/biac3/wandell4/data/reading_longitude/dti_y1234/' subjectCodes{subjID} '/t1/t1.nii.gz'];
    ni = readFileNifti(t1filename);
   [wm, gm, csf] = mrAnatSpmSegment(ni.data,ni.qto_xyz,'MNIT1');
wm_all(subjID)=sum(wm(:));
gm_all(subjID)=sum(gm(:));
csf_all(subjID)=sum(csf(:));
numvox(:, :, :, subjID)=size(wm);
end
wm_all=wm_all./255;
gm_all=gm_all./255;
csf_all=csf_all./255;

cd 
save('/biac3/wandell4/users/elenary/longitudinal/reading_longitud_wmgmcsf', 'wm_all', 'gm_all', 'csf_all', 'numvox');