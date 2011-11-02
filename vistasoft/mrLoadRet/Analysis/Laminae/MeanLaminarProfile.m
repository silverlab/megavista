function [mAmps, eAmps, t] = MeanLaminarProfile(deltaThick, scanIndex, ROIindex)

% [mAmps, eAmps, t] = MeanLaminarProfile(deltaThick, scanIndex, ROIindex);
%
% Calculate the laminar profile of mean map for the specified ROI. The
% calculation is performed only in the VOLUME view. Returns the mean value
% [mAmps], std. err. [eAmps], and bin centers [t].
%
% Ress, 10/04

mrGlobals

mAmps = [];
eAmps = [];
t = [];
if isempty(selectedVOLUME)
  Alert('Select a volume')
  return
end
view = VOLUME{selectedVOLUME};

if ~exist('deltaThick', 'var'), deltaThick = mean(view.mmPerVox); end
if ~exist('scanIndex', 'var'), scanIndex = getCurScan(view); end
if ~exist('ROIindex', 'var'), ROIindex = view.selectedROI; end

% Get the ROI data:
if ROIindex == 0
  Alert('Load and select an ROI')
  return
end
coords0 = view.ROIs(ROIindex).coords;
name = view.ROIs(ROIindex).name;

% Get laminar distance map:
if ~isfield(view, 'laminae')
  view = loadLaminae(view);
  if ~isfield(view, 'laminae')
    Alert('No laminar distance map!')
    return
  end
end

% Get the mean map:
if isempty(view.map) | ~strcmp(view.mapName, 'meanMap')
  view = loadMeanMap(view);
  if ~isempty(view.map)
    Alert('No mean map!')
    return
  end
end  

% Get laminar distance values for the ROI:
dims = size(view.anat);
inds = coords2indices(coords0, dims);
vol = repmat(NaN, dims);
vInds = coords2indices(view.coords, dims);
vol(vInds) = view.laminae;
tVals = vol(inds) * mean(view.mmPerVox);
vol = repmat(NaN, dims);
vol(vInds) = view.map{scanIndex};
ampVals = vol(inds);
nEmpty = sum(isnan(ampVals));
if nEmpty > 0
  disp(['Ignoring ' int2str(nEmpty) ' ROI voxels without anatomy data...'])
  ok = isfinite(ampVals);
  ampVals = ampVals(ok);
  tVals = tVals(ok);
end

% Create mean gray-level values with respect to laminar thickness:
tRange = max(tVals) - min(tVals);
nHist = ceil(tRange / deltaThick);
mAmps = zeros(nHist, 1);
eAmps = zeros(nHist, 1);
minT = min(tVals);
for iH=1:nHist
  maxT = minT + deltaThick;
  binInds = find((tVals >= minT) & (tVals < maxT));
  if isempty(binInds)
    mAmps(iH) = NaN;
    eAmps(iH) = 0;
  else
    z = ampVals(binInds);
    mAmps(iH) = mean(z);
    eAmps(iH) = std(z)/sqrt(length(z));
  end
  t(iH) = 0.5 * (minT + maxT);
  minT = maxT;
end


