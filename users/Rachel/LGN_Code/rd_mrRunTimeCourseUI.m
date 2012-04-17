function tcData = rd_mrRunTimeCourseUI(view, dt, roi, scanSets)
%
% INPUTS:
% view is view, eg. getCurView
% roi is names or indices of ROIs in the selected view
% dt is dataType, eg. 1 or 'Original' (for the Originals dataType)
% scans is a 1xnScans vector of scan numbers, eg. 2:9, so scanSets is a
% cell array of scans vectors
% queryFlag is 1 if you want to tell the user if wierd things are
% happening, 0 otherwise
%
% if anything is empty or left out, timeCourseUI will use the defaults.
% see timeCourseUI for more info.
%
% OUTPUTS:
% tc is a structure of time course info for that ROI
%
% Rachel Denison
% 15 April 2012

global dataTYPES

% view = INPLANE{1};
% dt = 1;
% roi = 'ROI201';
% scanSets = {2,3,4,5,6,7,8,9};
% scanSets = {2};
queryFlag = 1;

for iSS = 1:numel(scanSets)
    % set scans and view
    scans = scanSets{iSS};
    view = viewSet(view, 'curScan', scans(1));
    view = refreshScreen(view);
    
    % run time course ui
    tc0 = timeCourseUI(view, roi, scans, dt, queryFlag);
    tc = tc_visualizeGlm(tc0);
    
    % store data
    [scanNames{1:numel(scans)}] = deal(dataTYPES(dt).scanParams(scans).annotation);
    
    tcData(iSS).view = view.name;
    tcData(iSS).dataType = dataTYPES(dt).name;
    tcData(iSS).roi = roi;
    tcData(iSS).scans = scans;
    tcData(iSS).scanNames = scanNames;
    tcData(iSS).tc = tc;
end