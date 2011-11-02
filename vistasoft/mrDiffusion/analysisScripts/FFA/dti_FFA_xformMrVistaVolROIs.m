function dti_FFA_xformMrVistaVolROIs

% This script will transform specified ROIs defined on the mrVista
% volume to mrDiffusion and save them. It calls the function
% dtiXformMrVistaVolROIs to do this. 
%
% By: DY 03/2008

vAnatomy = '/biac1/kgs/projects/Kids/anat/adults/jc_27yo/vAnatomy.dat';
subDir = '/biac1/kgs/projects/Kids/dti/dp_presentation/adult_jc_27yo_051908/';
dt = fullfile('dti30','dt6.mat');
dt6file=fullfile(subDir,dt); 

fmriDir = '/biac1/kgs/projects/Kids/fmri/localizer/adult_jc_27yo_052408//Gray/ROIs/davie';
saveDir = fullfile(subDir,'dti30','ROIs','functional');

cd(fmriDir)
d=dir('*.mat');

for ii=1:length(d)
    ROIs{ii}=d(ii).name;
end

% ROIs = {'L_TOSp_IOvMCOJ_p3d.mat',...
%         'R_TOSp_IOvMCOJ_p3d.mat',...
%         'L_POSp_IOvMCOJ_p3d.mat',...
%         'R_POSp_IOvMCOJ_p3d.mat',...
%         'L_PPA_IOvMCOJ_p3d.mat',...
%         'R_PPA_IOvMCOJ_p3d.mat'};

for ii=1:length(ROIs)
    roiList{ii}=fullfile(fmriDir,ROIs{ii});
end

dtiXformMrVistaVolROIs(dt6file,roiList,vAnatomy,saveDir)