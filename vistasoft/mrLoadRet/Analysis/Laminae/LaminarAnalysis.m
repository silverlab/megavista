function [mm, ee, tt] = LaminarAnalysis(depthRange, roiList, extendROI)

% [ampProfiles, ampErrors, laminarPositions] = LaminarAnalysis(depthRange[, roiList, extendROIflag]);
%
% Perform analysis and create plots for specified list of ROIs. If
% unspecified, only the current ROI is analyzed.
%
% Ress, 10/04

mrGlobals

if ~exist('roiList', 'var'), roiList = VOLUME{selectedVOLUME}.selectedROI; end
if ~exist('extendROI', 'var'), extendROI = 0; end

nROIs = length(roiList);

mm = [];
ee = [];
tt = [];
for ii=1:nROIs
  iR = roiList(ii);
  VOLUME{selectedVOLUME} = selectROI(VOLUME{selectedVOLUME}, iR);
  if extendROI, ExtendLaminarROI(depthRange); end
  PlotMultipleMeanLaminarProfiles(VOLUME{selectedVOLUME});
  [m, e, t] = PlotMultipleLaminarProfiles(VOLUME{selectedVOLUME});
  mm = [mm, m];
  ee = [ee, e];
  tt = [tt, t];
  [ma, ea, ta] = AnatLaminarProfile;
  PlotLaminarProfiles(ta, ma, ea, [], VOLUME{selectedVOLUME}.ROIs(iR).name);
end
