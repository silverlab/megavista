% PennConvert2to3
%
% Converts mrSESSION to version 3 format.
% Creates dataTYPES.
% Saves them both to mrSESSION.mat
%
% This version is setup to run directly with our conversion from Analyze
% utilties.
%
% 3/26/2001     djh     Wrote it.
% 2/06/03       ggc     Rename, disable FOV since we've got it already.
% 5/16/03       dhb     Penn prefix.  Streamline for Analyze conversion.

% Set up new fields if they are missing.
if isfield(mrSESSION.analysis,'inhomoCorrection')
    inhomoCorrection = mrSESSION.analysis.inhomoCorrection;
else
    inhomoCorrection = 1;
end
if isfield(mrSESSION.analysis,'detrend')
    detrend = mrSESSION.analysis.detrend;
else
    detrend = 0;
end
nCycles = mrSESSION.nCycles;

% Convert mrSESSION
mrSESSION = PennConvertSession(mrSESSION);

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
HOMEDIR = pwd;
saveSession;

% Clean up
clear all
