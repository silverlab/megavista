% This script runs updatestats in order to generate a new weight file for
% paths that have been generated via SIS.

dir = 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac';
samplerOptsFile = fullfile(dir,'met_params_dlh.txt');

dt6File = 'c:\cygwin\home\sherbond\images\aab050307\aab050307_dt6.mat';
% load DT6 for met_params file loading
% Here is the dt6, probably don't need this if we expect the bin directory
% to exist
dt = load(dt6File);
dt.dt6(isnan(dt.dt6)) = 0;

% Load original params file
mtr = mtrLoad(samplerOptsFile,dt.xformToAcPc);

% Setup length penalties that we will calculate
smoothStd = [0.078 0.157 0.314 0.628 0.814 1.26 1.88 2.51];
lengthPenalty = [0.2 0.35 0.42 0.5 0.6 0.75 0.8 0.85 0.90 0.95];
numPaths = 1;

% Do all the length calculations
% for pp = 1:numPaths
%     pathOnlyName = sprintf('paths%d.dat',pp);
%     pathFilename = fullfile(dir,pathOnlyName);
%     tempFilename = fullfile(dir,'temp.dat');
%     weightOnlyName = sprintf('statvec%d_length.dat',pp);
%     weightFilename = fullfile(dir,weightOnlyName);
%     exeFilename = 'c:\cygwin\home\sherbond\src\dtivis\misc\updatestats.exe';
%     cmd = sprintf('%s -v %s -i %s -o %s -s 0 -sf %s', exeFilename, samplerOptsFile, pathFilename, tempFilename,  weightFilename);
% 
%     disp(cmd);
%     tic
%     system(cmd,'-echo');
%     toc
% end



for ss = 1:length(smoothStd)
    % Save out params file with updated length penalty
     mtr = mtrSet(mtr,'smooth_std',smoothStd(ss));
     run_filename = sprintf('run%d.sh',ss);
     run_fid = fopen(run_filename, 'w');
     fprintf(run_fid,'#!/bin/bash\n');
     
    for ll = 1:length(lengthPenalty)
        % Save out params file with updated length penalty
        mtr = mtrSet(mtr,'abs_normal',lengthPenalty(ll));
        smoothName = sprintf('smooth%d',floor(100*smoothStd(ss)));
        lenName = sprintf('len%d',floor(100*lengthPenalty(ll)));
        specificName = sprintf('met_params_%s_%s.txt',smoothName,lenName);
        samplerOptsFile = fullfile(dir,specificName);
        mtrSave(mtr,samplerOptsFile,dt.xformToAcPc);
        
        fprintf(run_fid,'~/src/dtivis/misc/updatestats.exe -v %s -i ../paths1.dat -o paths_temp.dat -s 4 -sf statvec1_iw_%s_%s;\n',specificName,smoothName,lenName);
        
        %% Just writing out parameters file right now

%         for pp = 1:numPaths
%             pathOnlyName = sprintf('paths%d.dat',pp);
%             pathFilename = fullfile(dir,pathOnlyName);
%             tempFilename = fullfile(dir,'temp.dat');
%             weightOnlyName = sprintf('statvec%d_iw_len%d.dat',pp,100*lengthPenalty(ll));
%             weightFilename = fullfile(dir,weightOnlyName);
%             exeFilename = 'c:\cygwin\home\sherbond\src\dtivis\misc\updatestats.exe';
%             cmd = sprintf('%s -v %s -i %s -o %s -s 4 -sf %s', exeFilename, samplerOptsFile, pathFilename, tempFilename,  weightFilename);
% 
%             disp(cmd);
%             tic
%             system(cmd,'-echo');
%             toc
%         end
    end
    fclose(run_fid);
end