% rd_restrictROIs

% need to have Inplane open and corAnal loaded

%% start mrVista
mrVista

%% set initial view
[dtNames{1:numel(dataTYPES)}] = deal(dataTYPES.name);
dt = find(strcmp(dtNames,'Averages'), 1);
if isempty(dt)
    error('Could not find data type "Averages"')
end
INPLANE{1} = viewSet(INPLANE{1}, 'curDataType', dt);

%% setup
cothresh = 0.20;
rois = {'ROI101','ROI201'};
newROIs = {'ROI109','ROI209'};

%% remove any ROIs already loaded
INPLANE{1} = deleteAllROIs(INPLANE{1});
INPLANE{1} = refreshScreen(INPLANE{1});

%% load coranal, view phase map
INPLANE{1} = loadCorAnal(INPLANE{1}); 
INPLANE{1} = setDisplayMode(INPLANE{1},'ph');
INPLANE{1} = refreshScreen(INPLANE{1}); 

%% set cothresh to new value
INPLANE{1} = setCothresh(INPLANE{1}, cothresh);
INPLANE{1} = refreshScreen(INPLANE{1}); 

%% load ROIs to restrict
INPLANE{1} = loadROI(INPLANE{1}, rois);
INPLANE{1} = refreshScreen(INPLANE{1});

%% rename ROIs
for iROI = 1:numel(rois)
    INPLANE{1}.ROIs(iROI).name = newROIs{iROI};
end
setROIPopup(INPLANE{1});

%% restrict ROIs
INPLANE{1} = restrictAllROIsfromMenu(INPLANE{1});
INPLANE{1} = refreshScreen(INPLANE{1});

%% save new ROIs
saveAllROIs(INPLANE{1}, 1);

%% clean up from this subject
close('all');
mrvCleanWorkspace;

