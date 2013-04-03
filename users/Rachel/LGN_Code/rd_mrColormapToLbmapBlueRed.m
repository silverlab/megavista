function graylbmapbr = rd_mrColormapToLbmapBlueRed(vw)

if ~exist('vw','var')
    vw = getCurView;
end

load graylbmapbr.mat

vw.ui.mapMode.cmap = graylbmapbr;
vw=refreshScreen(vw, 1);