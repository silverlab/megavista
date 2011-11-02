% This script illustrates how to run MetroTrac from the dtiFiberUI
% environment.  
%  MetroTrac in this case will find the highest scoring paths between
%  two ROIs.  For this example, we chose one ROI at the LGN and another in
%  V1.  These were selected from the dtiFiberUI and saved.  We will read
%  them here.
dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis\';
roiNames = {'start_tendon_VOI','end_VOI'};
dt6File = fullfile(dataDir,'dti3_dt6.mat');
roi1File = fullfile(dataDir,'ROIs',roiNames{1});
roi2File = fullfile(dataDir,'ROIs',roiNames{2});
fgName = ['paths-',strrep(strrep(datestr(now),':','-'),' ','-')];
fgFile = fullfile(dataDir,'bin','metrotrac',[fgName,'.dat']);
logFile = fullfile(dataDir,'bin','metrotrac',[fgName,'_log.txt']);
% If the bin directory containing these files exists, skip this.  Otherwise
% run it.  If it exists, but is older than August 25th 2006, you need to
% run this because MetroTrac only appeared in our hands that date.
%dtiConvertDT6ToBinaries(dt6File)
samplerOptsFile = fullfile(dataDir,'bin','metrotrac','met_params.txt');
mtrTwoRoiSampler(dt6File, roi1File, roi2File,samplerOptsFile, fgFile, logFile);
%outDir = [dataDir filesep 'bin' filesep 'metrotrac' filesep 'strat_test'];
%mtrStratifiedTwoRoiSamplerSetup(dt6File, roi1File, roi2File,samplerOptsFile, fgFile, logFile, outDir, 2);