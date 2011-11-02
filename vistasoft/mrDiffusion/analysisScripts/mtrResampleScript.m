% Resample script to run a couple resamplings with different importance
% weight files.

% Run metrotrac
%% MUST MAKE SURE THIS PROGRAM IS COMPILED AND IN RIGHT LOCATION
if(ispc)
    executable = which('updatestats.exe');
else
    error('Not compiled for Linux.');
end

args = sprintf(' -i %s -p %s', samplerOptsFile, fgFile);
cmd = [executable args];
disp(cmd); disp('...')
[s, ret_info] = system(cmd,'-echo');
disp('Done')

% Write out command line output from program
if (~ieNotDefined('samplerLogFile'))
    save(samplerLogFile,'ret_info','-ASCII');
end

% Import the resulting fiber group
fg = mtrImportFibers(fgFile, xform);

return;

% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec1_iw_len42.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1_resamp_len42.dat')
% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec1_iw_len80.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1_resamp_len80.dat')
% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec1_iw_len90.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1_resamp_len90.dat')
% 
% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec2_iw_len42.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths2.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths2_resamp_len42.dat')
% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec2_iw_len80.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths2.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths2_resamp_len80.dat')
% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec2_iw_len90.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths2.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths2_resamp_len90.dat')
% 
% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec3_iw_len42.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths3.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths3_resamp_len42.dat')
% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec3_iw_len80.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths3.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths3_resamp_len80.dat')
% resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec3_iw_len90.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths3.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths3_resamp_len90.dat')

resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec1_iw_len85.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1_resamp_len85.dat')
resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec2_iw_len85.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths2.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths2_resamp_len85.dat')
resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\statvec3_iw_len85.dat'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths3.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths3_resamp_len85.dat')


resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\params_search\statvec1_iw_smooth7_len20'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1_resamp_smooth7_len20.dat');
resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\params_search\statvec1_iw_smooth250_len50'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1_resamp_smooth250_len50.dat');
resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\params_search\statvec1_iw_smooth188_len60'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1_resamp_smooth188_len60.dat');
resampleSISPathways(400000, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\params_search\statvec1_iw_smooth81_len80'}, {'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1.dat'}, 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\paths1_resamp_smooth81_len80.dat');
