function [mAmps, eAmps, t] = ROIlaminarProfile(scanList, ROI)

% [amps, errs, t] = ROIlaminarProfile([scanList, ROI]);
%
% Calculate a laminar amplitude profile for a gray matter ROI. The
% optional input ROI defaults to the currently selected ROI. Only the
% layer-1 coordinates of the ROI are relevant to the calculation.
%
% Ress, 10/05

mrGlobals

mAmps = [];
eAmps = [];
t = [];

% Get appropriately prepared view:
selectedVOLUME = viewSelected('Volume');
if ~isfield(VOLUME{selectedVOLUME}, 'mmPerVox'), VOLUME{selectedVOLUME} = loadAnat(VOLUME{selectedVOLUME}); end
if ~strcmp(VOLUME{selectedVOLUME}.viewType, 'Gray'), VOLUME{selectedVOLUME} = switch2Gray(VOLUME{selectedVOLUME}); end
% Get laminarIndices if not in input list:
if ~isfield(VOLUME{selectedVOLUME}, 'laminarIndices'), LoadLaminarIndices; end
if ~isfield(VOLUME{selectedVOLUME}, 'laminarIndices')
  % If still not in the view, the user aborted the process, so quit
  return
end
view = VOLUME{selectedVOLUME};
vDims = size(view.anat);

% Set the ROI
if ieNotDefined('ROI')
  if ~isempty(view.ROIs)
    ROI = view.ROIs(view.selectedROI);
  else
    Alert('No ROI!')
    return
  end
end

% Get the layer-1 vertices
layer1Verts = view.coords(:, view.nodes(6, :) == 1);
nNodes = size(layer1Verts, 2);

% Build reverse-lookup volume
iVol = repmat(int32(0), vDims);
inds = coords2Indices(layer1Verts, vDims);
for ii=1:nNodes, iVol(inds(ii)) = ii; end

if ~exist('scanList', 'var'), scanList = getCurScan(view); end
if ~exist('ROI', 'var')
  ROI = view.ROIs(view.selectedROI);
end
if isempty(ROI)
  Alert('No ROI!');
  return
end

if ~exist('deltaThick', 'var'), deltaThick = mean(view.mmPerVox); end

% Use the reverse look-up table to extract the layer-1 node indices:
coords = ROI.coords;
L1inds = iVol(coords2Indices(coords, vDims));
L1inds = L1inds(L1inds > 0);
if isempty(L1inds)
  Alert('No layer-1 voxels in ROI!');
  return
end

% Concatenate together all of the laminar indices:
nInds = length(L1inds);
inds = [];
for ii=1:nInds
  inds = [inds, view.laminarIndices{L1inds(ii)}];
end
inds = unique(inds);

% Switch to volume view and load the amplitude data
view = switch2Vol(view);
view = loadCorAnal(view);
if isempty(view.amp)
  Alert('No amplitude data!');
  return
end

% Get laminar distance data
vInds = coords2indices(view.coords, vDims);
vol = repmat(NaN, vDims);
if ~isfield(view, 'laminae'), view = loadLaminae(view); end
vol(vInds) = view.laminae;
tVals0 = vol(inds) * mean(view.mmPerVox);

nScans = length(scanList);
mAmps = cell(nScans, 1);
eAmps = cell(nScans, 1);
t = cell(nScans, 1);
for iS=1:nScans
  scan = scanList(iS);
  tVals = tVals0;
  % Get the amplitude data:
  if isempty(view.amp{scan})
    disp(['No amplitude data for scan ', int2str(scan)]);
    break
  end
  vol(:) = NaN;
  vol(vInds) = view.amp{scan}.* exp(i*view.ph{scan});
  ampVals = vol(inds);

  % Remove undefined amplitude values (these were probably outside of the
  % Inplane prescription)
  nEmpty = sum(isnan(ampVals));
  if nEmpty > 0
    disp(['Ignoring ' int2str(nEmpty) ' ROI voxels without amplitude data...'])
    ok = isfinite(ampVals);
    ampVals = ampVals(ok);
    tVals = tVals(ok);
  end

  % Bin the data to form a profile:
  tRange = max(tVals) - min(tVals);
  nHist = ceil(tRange / deltaThick);
  mAmps{scan} = zeros(nHist, 1);
  eAmps{scan} = zeros(nHist, 1);
  t{scan} = zeros(nHist, 1);
  minT = min(tVals);
  for iH=1:nHist
    maxT = minT + deltaThick;
    binInds = find((tVals >= minT) & (tVals < maxT));
    if isempty(binInds)
      mAmps{scan}(iH) = NaN;
      eAmps{scan}(iH) = 0;
    else
      z = ampVals(binInds);
      mAmps{scan}(iH) = abs(mean(z));
      eAmps{scan}(iH) = std(z)/sqrt(length(z));
    end
    t{scan}(iH) = 0.5 * (minT + maxT);
    minT = maxT;
  end
end