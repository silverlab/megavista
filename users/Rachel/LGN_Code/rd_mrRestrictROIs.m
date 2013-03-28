% rd_restrictROIs

%% setup
cothresh = 0.17;
rois = {'ROI107','ROI207'};
newROIs = {'ROI108','ROI208'};
vw = INPLANE{1};

%% remove any ROIs already loaded
vw = deleteAllROIs(vw);
vw = refreshScreen(vw);

%% set cothresh to new value
vw = setCothresh(vw, cothresh);

%% load ROIs to restrict
vw = loadROI(vw, rois);
vw = refreshScreen(vw);

%% rename ROIs
for iROI = 1:numel(rois)
    vw.ROIs(iROI).name = newROIs{iROI};
end
setROIPopup(vw);

%% restrict ROIs
vw = restrictAllROIsfromMenu(vw);
vw = refreshScreen(vw);

%% save new ROIs
saveAllROIs(vw, 1);

%% reset INPLANE{1}
INPLANE{1} = vw;
