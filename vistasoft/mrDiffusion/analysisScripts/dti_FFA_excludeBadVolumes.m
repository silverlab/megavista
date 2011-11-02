function dti_FFA_excludeBadVolumes(dt6Dir,excludeVols)
%
% Usage: dti_FFA_excludeBadVolumes(dt6Dir,excludeVols)
%
% dt6dir: fullpath to directory with dt6.mat file
% excludeVols: array with list of volumes to exclude (e.g., [70 71])
%
% This will go the dt6 directory specified and call dtiRawPreprocess to
% recompute the tensors (setting clobber to false, so all previous steps
% are preserved). It will rename the previous dt6Directory to a new name,
% as a new directory will be created that has the same name (dti30). 
%
% It will also write what happened in the log file for all subjects. 
% This process should only take a few moments per person. 
%
% IMPORTANT: assumes that g=865, b=900, freqDir=L/R
% IMPORTANT: run this on teal, not my PC because of movefile command
% IMPORTANT: we clip negative eigenvalues to 0
%
% By: DY 2008/07/16

% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\';
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/';
end
[path,subName]=fileparts(mrvDirup(dt6Dir));

% Record keeping steps -- rename the old dti30 directory
allDir='dti30_allVols';
excludeDir='dti30_excludeVols';
theSubDir=mrvDirup(dt6Dir);
movefile(dt6Dir, fullfile(theSubDir,allDir));
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(dtiDir,'logs',['ExcludeBadVolumes.txt']);
fid=fopen(logFile,'a');

% Here we actually call dtiRawPreprocess again
cd(theSubDir);
dtiNifti=fullfile(theSubDir,'raw','dti_g865_b900.nii.gz');
thet1=fullfile(theSubDir,'t1','t1.nii.gz');
dtiRawPreprocess(dtiNifti,thet1,.9,865,false,[],0,excludeVols);

% Clip negative eigenvalues to 0 for tensor files
try
    dt6file=fullfile(dt6Dir,'dt6.mat');
    tensorfile=fullfile(dt6Dir,'bin','tensors.nii.gz');
    dtiFixTensorsAndDT6(dt6file,tensorfile);
    tensorMessage=['Tensors clipped for ' subName];
catch
    tensorMessage=['FAILURE TO CLIP TENSORS for ' subName];
end

movefile(dt6Dir, fullfile(theSubDir,excludeDir));

% Here we note what we did in the log file
excluded=sprintf('%d ', excludeVols)
fprintf(fid,'\n Processed %s on %s',subName,dateAndTime);
fprintf(fid,'\n Excluded vols: %s',excluded);
fprintf(fid,'\n %s \n',tensorMessage);
fclose(fid); 