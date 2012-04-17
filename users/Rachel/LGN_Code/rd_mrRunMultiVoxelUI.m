function mvData = rd_mrRunMultiVoxelUI(view, dt, roi, scanSets)
%
% INPUTS:
% view is view, eg. getCurView
% roi is names or coords of ROIs in the selected view
% dt is dataType, eg. 1 (for the Original dataType)
% scans is a 1xnScans vector of scan numbers, eg. 2:9, so scanSets is a
% cell array of scans vectors
%
% if anything is empty or left out, multiVoxelUI will use the defaults.
% see multiVoxelUI for more info.
%
% OUTPUTS:
% mv is a structure of multi voxel info for that ROI
%
% Rachel Denison
% 15 April 2012

global dataTYPES

% view = INPLANE{1};
% dt = 1;
% roi = 'ROI201';
% scanSets = {2,3,4,5,6,7,8,9};
% scanSets = {2};

for iSS = 1:numel(scanSets)
    % set scans and view
    scans = scanSets{iSS};
    view = viewSet(view, 'curScan', scans(1));
    view = refreshScreen(view);
    
    % mv figure window
    mv0 = multiVoxelUI(view, roi, scans, dt);
    
    % run glm
    mv_selectPlotType(9); 
    mv_visualizeGlm; 
    
    % get mv structure from figure
    mv = get(gcf, 'UserData');
    
    % store data
    [scanNames{1:numel(scans)}] = deal(dataTYPES(dt).scanParams(scans).annotation);
    
    mvData(iSS).view = view.name;
    mvData(iSS).dataType = dataTYPES(dt).name;
    mvData(iSS).roi = roi;
    mvData(iSS).scans = scans;
    mvData(iSS).scanNames = scanNames;
    mvData(iSS).mv = mv;
end