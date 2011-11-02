function cc = LaminateROIs(deltaThick, ROIindex)

% cc = LaminateROIs(deltaThick, ROIindex);
%
% Divide the specified ROI into a series of laminar ROIs, each
% corresponding to a particular range of laminar distance values. The 
% calculation is performed only in the VOLUME view. Returns the coordinates
% of the new ROIs as a cell array.
%
% Ress, 06/04

mrGlobals

cc = [];
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
baseName = view.ROIs(ROIindex).name;
baseColor = view.ROIs(ROIindex).color;
if ~isfield(view, 'laminae')
  view = loadLaminae(view);
  if ~isfield(view, 'laminae')
    Alert('No laminar distance map!')
    return
  end
  VOLUME{selectedVOLUME} = view;
end
if isempty(view.amp)
  view = loadCorAnal(view);
  if isempty(view.amp)
    Alert('No corAnal!')
    return
  end
  VOLUME{selectedVOLUME} = view;
end

dims = size(view.anat);
inds = coords2indices(coords0, dims);
vol = repmat(NaN, dims);
vInds = coords2indices(view.coords, dims);
vol(vInds) = view.laminae;
tVals = vol(inds)  * mean(view.mmPerVox);
tRange = max(tVals) - min(tVals);
nHist = ceil(tRange / deltaThick);
cc = cell(nHist, 1);
t = zeros(nHist, 1);
minT = min(tVals);
for iH=1:nHist
  maxT = minT + deltaThick;
  binInds = find((tVals >= minT) & (tVals < maxT));
  if isempty(binInds)
    coords = [];
  else
    coords = indices2Coords(inds(binInds), dims);
    name = [baseName, '-', int2str(iH)];
    view = newROI(view, name);
    view.ROIs(view.selectedROI).coords = coords;
    if ~isstr(baseColor)
      newColor = baseColor + (1 - baseColor)*0.7*iH/nHist;
      view.ROIs(view.selectedROI).color = newColor;
    end
    VOLUME{selectedVOLUME} = view;
  end
  cc{iH} = coords;
  t(iH) = 0.5 * (minT + maxT);
  minT = maxT;
end
