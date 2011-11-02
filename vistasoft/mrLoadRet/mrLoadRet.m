%script
% 
%  mrLoadRet, version 3.0
%
% AUTHOR:   Many people.  This form initiated by Wandell/Heeger
% PURPOSE:  Everything.
% DATE:     Jan 10, 1998
%
% This is the default mrLoadRet script that simply opens an
% inplaneView window.  You are encouraged to put a copy of this
% file in each of your data directories and modify the copied
% version of this script to customize it for that data set.
% Examples of a number of possible customizations are commented
% below.

% Define global variables and structures.
mrGlobals;
if (~isempty(vANATOMYPATH))
    disp('Clearing vANATOMYPATH');
    vANATOMYPATH='';
end

% Check Matlab version number
expectedMatlabVersion = [6 6.1 6.5 7.0];  % Change this after testing Matlab upgrades
version = ver('Matlab');
matlabVersion = str2num(version.Version);        
if ~ismember(matlabVersion, expectedMatlabVersion);    % (matlabVersion ~= expectedMatlabVersion)
    myWarnDlg(['mrLoadRet ',num2str(mrLoadRetVERSION),' is intended for Matlab 6 or 7. You are running Matlab ',version.Version]);
else
    disp(['mrLoadRet ',num2str(mrLoadRetVERSION),', Matlab ',version.Version]);
end

% Load mrSESSION structure
loadSession;

% Set HOMEDIR and vANATOMYPATH
HOMEDIR = pwd;
vANATOMYPATH = getvAnatomyPath(mrSESSION.subject);

% Open inplane window
openInplaneWindow;

% Clean up
clear expectedMatlabVersion version matlabVersion
