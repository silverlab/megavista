function [mAmps, eAmps, t] = AnatLaminarProfile(deltaThick, ROIindex)

% [mAmps, eAmps, t] = AnatLaminarProfile(deltaThick, ROIindex);
%
% Calculate the laminar anatomy profile of the specified ROI. The
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
if ~exist('ROIindex', 'var'), ROIindex = view.selectedROI; end
if ROIindex == 0
  Alert('Load and select an ROI')
  return
end

coords0 = view.ROIs(ROIindex).coords;
name = view.ROIs(ROIindex).name;
if ~isfield(view, 'laminae')
  view = loadLaminae(view);
  if ~isfield(view, 'laminae')
    Alert('No laminar distance map!')
    return
  end
end

dims = size(view.anat);
inds = coords2indices(coords0, dims);
vol = repmat(NaN, dims);
vInds = coords2indices(view.coords, dims);
vol(vInds) = view.laminae;
tVals0 = vol(inds)  * mean(view.mmPerVox);
tVals = tVals0;
ampVals = view.anat(inds);
nEmpty = sum(isnan(ampVals));
if nEmpty > 0
  disp(['Ignoring ' int2str(nEmpty) ' ROI voxels without anatomy data...'])
  ok = isfinite(ampVals);
  ampVals = ampVals(ok);
  tVals = tVals(ok);
end
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


