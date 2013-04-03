% rd_mrRunUIAll.m

% This function runs a multiVoxel or timeCouse analysis on all scans
% together from the GLM scan group. figData files are saved.
% In contrast, rd_mrRunUI runs the analysis on each individual scan and
% uiData files are saved.

%% File I/O
% hemi = 2;
roiNumber = 2;
% uiType = 'multiVoxel'; % 'timeCourse' or 'multiVoxel'

switch uiType
    case 'timeCourse'
        uiExt = 'timeCourseData';
    case 'multiVoxel'
        uiExt = 'multiVoxFigData';
    otherwise
        error('uiType not recognized')
end

saveData = 1;
fileName = sprintf('ROIAnalysis/ROIX%02d/lgnROI%d_%s.mat', roiNumber, hemi, uiExt);
roiName = sprintf('ROI%d%02d', hemi, roiNumber);

%% Start mrVista
mrVista

%% Set initial view and scan
view = INPLANE{1};
dt = 1; % Original
roi = roiName;
scanInGroup = 3; % Original scan 3 should be in the mp scan group

%% Load ROI, set view to selected datatype
view = viewSet(view, 'curDataType', dt);
view = loadROI(view, roi);
view = refreshScreen(view);

%% Set scans
% get the scans in the scan group
scans = er_getScanGroup(view, scanInGroup);
fprintf('***Running %s UI for %s\n***Scans %s\n', uiType, roi, num2str(scans))

% use all scans together
scanSets = {scans};

%% Run UI
switch uiType
    case 'timeCourse'
        uiData = rd_mrRunTimeCourseUI(view, dt, roi, scanSets);
        figData = uiData.tc;
    case 'multiVoxel'
        uiData = rd_mrRunMultiVoxelUI(view, dt, roi, scanSets);
        figData = uiData.mv;
    otherwise
        error('uiType not recognized')
end

%% Save data
if saveData
    save(fileName, 'figData');
end

%% Clean up from this subject
close('all');
mrvCleanWorkspace;
