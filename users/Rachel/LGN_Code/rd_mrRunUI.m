% rd_mrRunUI.m

%% File I/O
hemi = 2;
saveData = 1;
fileBase = sprintf('ROIAnalysis/ROIX01/lgnROI%d_indivScanData', hemi);
% fileBase = sprintf('ROIAnalysis/Runs1-5/ROIX02/lgnROI%d_indivScanData', hemi);
roiName = sprintf('ROI%d01', hemi);

%% Start mrVista
mrVista

%% Set initial view and scan
view = INPLANE{1};
dt = 1;
roi = roiName;
uiType = 'multiVoxel'; % 'timeCourse' or 'multiVoxel'
scanInGroup = 3; % Original scan 3 should be in the mp scan group

%% Load ROI, set view to selected datatype
view = viewSet(view, 'curDataType', dt);
view = loadROI(view, roi);
view = refreshScreen(view);

%% Set scans
% get the scans in the scan group
scans = er_getScanGroup(view, scanInGroup);

% convert to cell array of individual scans
scanSets = num2cell(scans,1);

%% Run UI
switch uiType
    case 'timeCourse'
        uiData = rd_mrRunTimeCourseUI(view, dt, roi, scanSets);
    case 'multiVoxel'
        uiData = rd_mrRunMultiVoxelUI(view, dt, roi, scanSets);
    otherwise
        error('uiType not recognized')
end

[uiData(:).uiType] = deal(uiType);

%% Save data
fileName = sprintf('%s_%s_%s.mat', fileBase, uiType, datestr(now,'yyyymmdd'));
if saveData
    save(fileName, 'uiData');
end

%% Clean up from this subject
close('all');
mrvCleanWorkspace;


