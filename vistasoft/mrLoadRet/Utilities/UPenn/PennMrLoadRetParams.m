% mrLoadRetParams
%
% This is a parameter file to be executed by 
% PennMakeMrLoadRetSession.  The idea is that
% you can store the parameters for each session
% without modifying the underlying routine.
%
% PennMakeMrLoadRetSession should be run with
% the current working directory as the
% directory containing this file.
%
% Paths and filenames below should be entered
% relative to the directory containing this file.
%
% 5/15/03  dhb  Wrote it.

% Define subject
mrSESSION.subject= 'qrs';

% Where is the inplane anatomical data?
anatFileBaseDir = pwd;
anatomyInplaneDir = '050503/structural';            % anatomical data file directory
anatomyRootName = 'dummy';                          % anatomical data file name
anatomyRotate = 0;                                  % # 90 degree rotations to apply to anatomies.

% Information about functional data and design.  You can have multiple
% scans entered here.  Each scan should have an entry in sourceSubDirArray,
% sourceRootArray, and sourceRootFirstFrames.  That is, all three of these
% lists must have the same length, and that length should be equal to the
% number of scans.  The design for all functional scans is currently
% required to be the same.
funcFileBaseDir = pwd;
sourceSubDirArray = {'050503/functional/wedge1' '050503/functional/wedge2' '050503/functional/wedge3'}; % each of these contains a functional scan
sourceRootArray = {'wedge1_' 'wedge2_' 'wedge3_'};    % root filename for functional time slices
sourceRootFirstFrames = [1 1 1];                      % index counter for first time slice (usually 0 or 1)
mrSESSION.nCycles = 10;             % #times though cycle of independent variable
mrSESSION.frameRate = 3;            % seconds per frame in time series (TR time in our hands)
mrSESSION.nFrames=160;              % number of usable time frames for individual tSeries
mrSESSION.junkFirstFrames=5;        % throwaway frames at start              
mrSESSION.junkLastFrames=0;         % throwaway frames at end
functionalRotate = 0;               % # 90 degree functional rotations
functionalScale = 1;                % scale factor for functionals
functionalFlip = 0;                 % boolean: flip functionals?

% Where should the mrLoadRet project go?  This directory is created if it
% doesn't exist.  If it does exist, it is deleted and then created.  You
% do, however, get asked first if you really want to overwrite whatever you
% had in this directory.
mrLoadRetBaseDir = pwd;
mrLoadRetDirName = 'mrLoadRetWedge';

% Additional parameters
mrSESSION.analysis.detrend = 0;                   % switch: take out slow trend in time series?
mrSESSION.analysis.inhomoCorrection = 0;          % switch: take out local inomogeneity in data?
mrSESSION.curType=1;                              % what does this do?
mrSESSION.reconVersion='foo';                     % don't know ('local_MPI_Brucker' was once here)

% Some precomputes
mrSESSION.nScans=length(sourceSubDirArray);
mrSESSION.homeDir=mrLoadRetDirName;