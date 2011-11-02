function group=dti_FFA_calculateTensorReliabilityScript

% Usage: group = dti_FFA_calculateTensorReliabilityScript
% group: a struct with variance data for each subject divided by age group
%
% By: DY 2008/03/20
%
% This script will go through the Kids project DTI directory, and look in
% the three different age directories for subjects that have already been
% preprocessed. It then calls dtiCalculateTensorReliability for each
% subject. This function will create and save histograms of variance for
% fa, md, and pdd for that individual in the white matter. The script will
% then compute summary statistics
%
% Modified 2008/07/16 to deal with new directory structure and also point
% to subjects dt6 dir rather than top-level subject directory. 

% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\';
%     dtiDir = 'S:\reading_longitude'; % Use for wandell lab data
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/';
end
cd(dtiDir); s = dir('*0*');  subs={s.name};
dt6DirAll='dti30';
dt6DirExclude='dti30_excludeVols';

counter=0;
for ii=1:length(subs)
    counter=counter+1;
    thisDir = fullfile(dtiDir,subs{ii}); cd(thisDir);
    inds=strfind(subs{ii},'_'); g=min(inds); n=inds(2);
    groupName=subs{ii}(1:g-1);
    subName=subs{ii}(g+1:n-1);
    
    switch groupName
        case 'adolescent'
            jj=1;
        case 'adult'
            jj=2;
        case 'kid'
            jj=3;
    end

    % Loop through and check if they have been preprocessed (dti30 and
    % dt6.mat exist)
    if(exist(dt6Dir,'dir')&&exist(fullfile(dt6Dir,'dt6.mat'),'file'))
        thisDir=fullfile(thisDir,dt6Dir);
        [fa_std,md_std,pdd_disp]=dtiCalculateTensorReliability(thisDir,'images');
        group(jj).subjects{counter}=subName;
        group(jj).fastd_mean(counter)=mean(fa_std);
        group(jj).fastd_std(counter)=std(fa_std);
        group(jj).mdstd_mean(counter)=mean(md_std);
        group(jj).mdstd_std(counter)=std(md_std);
        group(jj).pdd_mean(counter)=std(pdd_disp);
        group(jj).pdd_std(counter)=std(pdd_disp);
    end
end
    
    