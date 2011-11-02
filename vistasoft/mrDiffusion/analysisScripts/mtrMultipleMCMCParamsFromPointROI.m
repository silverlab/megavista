
subject = 'sil';
if(strcmp(subject,'sil'))
    dataDir = 'c:\cygwin\home\sherbond\images\sil_nov05\dti3_ser7\analysis';
    dt6File = fullfile(dataDir,'dti3_ser7_dt6.mat');
    outputDir = 'bin\metrotrac\gastroc';
    roiNames = {'tendon_plate_points','end_voi'};
elseif(strcmp(subject,'tony'))
    dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis';
    dt6File = fullfile(dataDir,'dti3_dt6.mat');
    outputDir = 'bin\metrotrac\tendon_small';
    roiNames = {'tendon_sub_slice','end_VOI'};
elseif(strcmp(subject,'thor'))
    dataDir = 'c:\cygwin\home\sherbond\images\thor_nov05\dti4_ser11\analysis';
    dt6File = fullfile(dataDir,'dti4_ser11_dt6.mat');
    outputDir = 'bin\metrotrac\gastroc';
    roiNames = {'tendon_plate_points','end_voi'};
else
    error('Unknown subject.');
end

dt = load(dt6File,'xformToAcPc');

% First ROI we will break into separate ROIs
roi1File = fullfile(dataDir,'ROIs',roiNames{1});
roi2File = fullfile(dataDir,'ROIs',roiNames{2});

% Take all parameters from script except the ROIs
samplerOptsFile = fullfile(dataDir,'bin','metrotrac','met_params_fordlh.txt');

% Get sampler options file
fid = fopen(samplerOptsFile,'r');
if(fid ~= -1)
    fclose(fid);
    mtr = mtrLoad(samplerOptsFile,dt.xformToAcPc);
else
    error('Unable to open sampler parameters file.');
end

% Put ROIs into MetroTrac structure
roi1 = dtiReadRoi(roi1File);
roi2 = dtiReadRoi(roi2File);
mtr = mtrSet(mtr,'roi',roi2.coords,2,'coords');

for cc = 1:size(roi1.coords,1)
    % Must make a point set around this point two points will do.
    temp_coords = roi1.coords(cc,:)+[1 1 1];
    temp_coords(2,:) = roi1.coords(cc,:)-[1 1 1];
    mtr = mtrSet(mtr,'roi',temp_coords,1,'coords');
    samplerOutFilename = sprintf('met_params_%s_%s_%d.txt',roiNames{1},roiNames{2},cc);
    samplerOutFilename = fullfile(dataDir,outputDir,samplerOutFilename);
    % Write params file out because we are going to run a separate executable
    mtrSave(mtr,samplerOutFilename,dt.xformToAcPc);
end

num_scripts = 16;
num_repeats = 4;
num_runs_per_script = size(roi1.coords,1)*num_repeats/num_scripts;
num_rois_per_script = num_runs_per_script / num_repeats;
for ss = 1:num_scripts
    run_filename = sprintf('runMCMC_%d.sh',ss);
    run_filename = fullfile(dataDir,outputDir,run_filename);
    run_fid = fopen(run_filename, 'w');
    fprintf(run_fid,'#!/bin/bash\n');
    for ii = 1:num_runs_per_script
        roinum = (ss-1)*num_rois_per_script + ceil(ii/num_repeats);
        samplerOutFilename = sprintf('met_params_%s_%s_%d.txt',roiNames{1},roiNames{2},roinum);
        pathsName = sprintf('paths_%d_%d.dat',mod(ii-1,num_repeats)+1,roinum);
        fprintf(run_fid,'~/src/dtivis/DTIPrecomputeApp/dtiprecompute_met -i %s -p %s;\n',samplerOutFilename,pathsName);
    end
    fclose(run_fid);
end