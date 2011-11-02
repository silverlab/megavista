function [mAmps, eAmps, t] = LaminarProfile(deltaThick, scanList, ROIindex)

% [mAmps, eAmps, t] = LaminarProfile(deltaThick, scanList, ROIindex);
%
% Calculate the laminar amplitude profile of the specified ROI. The
% calculation is performed only in the VOLUME view. Returns the mean value
% [mAmps], std. err. [eAmps], and bin centers [t].
%
% Ress, 06/04

mrGlobals

mAmps = [];
eAmps = [];
t = [];
if isempty(selectedVOLUME)
  Alert('Select a volume')
  return
end
view = VOLUME{selectedVOLUME};

if ~exist('scanList', 'var'), scanList = getCurScan(view); end
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
if isempty(view.amp)
  view = loadCorAnal(view);
  if isempty(view.amp)
    Alert('No corAnal!')
    return
  end
end
dims = size(view.anat);
inds = coords2indices(coords0, dims);
vol = repmat(NaN, dims);
vInds = coords2indices(view.coords, dims);
vol(vInds) = view.laminae;
tVals0 = vol(inds)  * mean(view.mmPerVox);
nScans = length(scanList);
mAmps = cell(nScans, 1);
eAmps = cell(nScans, 1);
t = cell(nScans, 1);
for iS=1:nScans
  scan = scanList(iS);
  tVals = tVals0;
  vol(:) = NaN;
  vol(vInds) = view.amp{scan};
  ampVals = vol(inds);
  vol(vInds) = view.ph{scan};
  phVals = vol(inds);
  nEmpty = sum(isnan(ampVals));
  if nEmpty > 0
    disp(['Ignoring ' int2str(nEmpty) ' ROI voxels without amplitude data...'])
    ok = isfinite(ampVals);
    ampVals = ampVals(ok);
    phVals = phVals(ok);
    tVals = tVals(ok);
  end
  zVals = ampVals .* exp(i*phVals);
  tRange = max(tVals) - min(tVals);
  nHist = ceil(tRange / deltaThick);
  mAmps{scan} = zeros(nHist, 1);
  eAmps{scan} = zeros(nHist, 1);
  minT = min(tVals);
  for iH=1:nHist
    maxT = minT + deltaThick;
    binInds = find((tVals >= minT) & (tVals < maxT));
    if isempty(binInds)
      mAmps{scan}(iH) = NaN;
      eAmps{scan}(iH) = 0;
    else
      z = zVals(binInds);
      mAmps{scan}(iH) = abs(mean(z));
      eAmps{scan}(iH) = std(z)/sqrt(length(z));
    end
    t{scan}(iH) = 0.5 * (minT + maxT);
    minT = maxT;
  end
end

