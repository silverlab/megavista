function thick = MapLaminarThickness(laminarIndex, nTransverse)

% thick = MapLaminarThickness(laminarIndex, nTransverse)
%
% Calculate the laminar thickness of the specified laminarIndex map. This
% thickness is defined as the mean number of gray-classification voxels
% that are present in the transverse flat-map ROI. The calculation is
% performed in the GRAY view. Returns the mean thickness as a matrix with
% the same geometry as the original flat map. Bad values, e.g. from empty
% cells, are flagged as NaNs for the thickness value.
%
% Ress, 11/04

mrGlobals

thick = repmat(NaN, size(laminarIndex));

if isempty(selectedVOLUME)
  Alert('Select a volume')
  return
end
view = VOLUME{selectedVOLUME};
if ~isfield(view, 'nodes')
  view = switch2Gray(view);
  view = switch2Vol(view);
end

if ~isfield(view, 'laminae')
  view = loadLaminae(view);
  if ~isfield(view, 'laminae')
    Alert('No laminar distance map!')
    return
  end
  VOLUME{selectedVOLUME} = view;
end

dims = size(view.anat);
volC = repmat(logical(0), dims);
nLayers = max(view.nodes(6, :));
volC(coords2Indices(view.nodes([2 1 3], :), dims)) = logical(1);
vol = repmat(NaN, dims);
vInds = coords2indices(view.coords, dims);
vol(vInds) = view.laminae;

nCells = length(laminarIndex(:));
waitH = waitbar(0, 'Calculating anatomical thickness map...');
area = nTransverse^2;
t0 = mean(view.mmPerVox);
for ii=1:nCells
  waitbar(ii/nCells, waitH);
  inds = laminarIndex{ii};
  if ~isempty(inds)
    tVals = vol(inds) * t0;
    cVals = volC(inds);
    ok = isfinite(tVals);
    cVals = cVals(ok);
    thick(ii) = sum(cVals) / area * t0;
  end
end
close(waitH)