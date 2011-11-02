% script convert2to3
%
% Converts mrSESSION to version 3 format.
% Creates dataTYPES.
% Saves them both to mrSESSION.mat
%
% Copy the existing version 2.5 directory to a new place.  GO to that new place.  Run
% this script.
%
% djh, 3/26/2001
%
%

mrGlobals

HOMEDIR = pwd;

but = questdlg('This will delete all of your corAnal.mat files and other parameter map files. Your ROIs files will not be touched. Are you sure you want to continue?');
if ~strcmp(but,'Yes')
    return
end

% Load old mrSESSION
if exist('mrSESSION.mat','file')
    load mrSESSION;
else
    myErrorDlg('No mrSESSION file here.')
end

if isfield(mrSESSION,'mrLoadRetVersion') & (mrSESSION.mrLoadRetVersion >= 3)
    myErrorDlg('This session already appears to have been converted to mrLoadRet version 3.')
end

Alert('Make sure that all subdirectories and *.mat files are writable.');

% Clean up all the data directories
copyfile(fullfile(HOMEDIR,'Inplane','anat.mat'),fullfile(HOMEDIR,'Inplane','anat.mat.BAK'));
delete(fullfile(HOMEDIR,'Inplane','*.mat'));
copyfile(fullfile(HOMEDIR,'Inplane','anat.mat.BAK'),fullfile(HOMEDIR,'Inplane','anat.mat'));
delete(fullfile(HOMEDIR,'Inplane','anat.mat.BAK'));
delete(fullfile(HOMEDIR,'Volume','*.mat'));
delete(fullfile(HOMEDIR,'Gray','*.mat'));
[nDirs,dirList] = countDirs(fullfile(HOMEDIR,'Flat*'));
for d = 1:nDirs
    delete(fullfile(HOMEDIR,dirList{d},'*.mat'));
end

% Convert tSeries.dat to tSeries.mat
convertDatToMat(fullfile(HOMEDIR,'Inplane','TSeries'));

% Grab analysis params
nCycles = mrSESSION.nCycles;
detrend = mrSESSION.analysis.detrend;
if isfield(mrSESSION.analysis,'inhomoCorrection')
    inhomoCorrection = mrSESSION.analysis.inhomoCorrection;
else
    inhomoCorrection = 1;
end

% Convert mrSESSION
mrSESSION = convertSession(mrSESSION);

% Build dataTypes & add in the analysis params
dataTYPES(1).name = 'Original';
for s = 1:length(mrSESSION.functionals)
    dataTYPES(1).scanParams(s).annotation = '';
    dataTYPES(1).scanParams(s).nFrames = mrSESSION.functionals(s).nFrames;
    dataTYPES(1).scanParams(s).framePeriod = mrSESSION.functionals(s).framePeriod;
    dataTYPES(1).scanParams(s).slices = mrSESSION.functionals(s).slices;
    dataTYPES(1).scanParams(s).cropSize = mrSESSION.functionals(s).cropSize;
end
for s = 1:length(mrSESSION.functionals)
    dataTYPES(1).blockedAnalysisParams(s).blockedAnalysis = 1;
    dataTYPES(1).blockedAnalysisParams(s).detrend = detrend;
    dataTYPES(1).blockedAnalysisParams(s).inhomoCorrect = inhomoCorrection;
    dataTYPES(1).blockedAnalysisParams(s).nCycles = nCycles;
end
for s = 1:length(mrSESSION.functionals)
    dataTYPES(1).eventAnalysisParams(s).eventAnalysis = 0;
end

% Save new mrSESSION and dataTYPES
saveSession;

msgbox(sprintf('Conver2to3 is finished. Now, it is up to you to:\n (a) Make Inplane/Original and move Inplane/TSeries there.\n (b) Delete Gray/TSeries.\n (c) Delete Volume/TSeries.\n (d) Delete Flat*/TSeries.'));

% Clean up
clear all
