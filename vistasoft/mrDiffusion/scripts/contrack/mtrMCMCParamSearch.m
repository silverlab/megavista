% This script runs updatestats in order to generate a new weight file for
% paths that have been generated via SIS.

dir = 'c:\cygwin\home\sherbond\images\md040714\bin\metrotrac\fine_param_search';
samplerOptsFile = fullfile(dir,'met_params_dlh.txt');

dt6File = 'c:\cygwin\home\sherbond\images\md040714\md040714_dt6.mat';
% load DT6 for met_params file loading
% Here is the dt6, probably don't need this if we expect the bin directory
% to exist
dt = load(dt6File);
dt.dt6(isnan(dt.dt6)) = 0;

% Load original params file
mtr = mtrLoad(samplerOptsFile,dt.xformToAcPc);

% Setup length penalties that we will calculate
%smoothStd = [0.078 0.157 0.314 0.628 0.814 1.26 1.88 2.51];
%lengthPenalty = [0.2 0.35; 0.42 0.5; 0.6 0.75; 0.8 0.85; 0.90 0.95];
smoothStd = [0.61 0.619 0.628 0.637 0.646];
lengthPenalty = [0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95];

num_scripts = 16;
num_repeats = 4;
num_runs_per_script = ones(num_scripts,1)*floor(length(smoothStd)*length(lengthPenalty)*num_repeats/num_scripts);
temp_extra = mod(length(smoothStd)*length(lengthPenalty)*num_repeats,num_scripts);
num_runs_per_script(1:temp_extra) =  num_runs_per_script(1:temp_extra)+1;
num_runs_per_script = [0; cumsum(num_runs_per_script)];

scriptcount = 1;
for ss = 1:length(smoothStd)
    % Save out params file with updated smooth penalty
    mtr = mtrSet(mtr,'smooth_std',smoothStd(ss));

    for ll = 1:length(lengthPenalty)
        % Save out params file with updated length penalty
        mtr = mtrSet(mtr,'abs_normal',lengthPenalty(ll));
        smoothName = sprintf('smooth%d',floor(1000*smoothStd(ss)));
        lenName = sprintf('len%d',floor(100*lengthPenalty(ll)));
        samplerOptsName = sprintf('met_params_%s_%s.txt',smoothName,lenName);
        samplerOptsFile = fullfile(dir,samplerOptsName);
        mtrSave(mtr,samplerOptsFile,dt.xformToAcPc);

        for rr = 1:num_repeats
            runNumber = (ss-1)*length(lengthPenalty)*num_repeats+(ll-1)*num_repeats + rr;
            if(runNumber > num_runs_per_script(scriptcount))
                % Open a new script
                if(scriptcount>1)
                    fclose(run_fid);
                end
                run_filename = sprintf('runMCMC_%d.sh',scriptcount);
                run_filename = fullfile(dir,run_filename);
                run_fid = fopen(run_filename, 'w');
                fprintf(run_fid,'#!/bin/bash\n');
                scriptcount = scriptcount+1;
            end
            pathsName = sprintf('paths_%s_%s_%d.dat',smoothName,lenName,rr);
            fprintf(run_fid,'~/src/dtivis/DTIPrecomputeApp/dtiprecompute_met -i %s -p %s;\n',samplerOptsName,pathsName);
        end
    end
end

fclose(run_fid);
