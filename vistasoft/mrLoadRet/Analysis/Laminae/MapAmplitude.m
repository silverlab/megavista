function map = MapAmplitude(laminarIndex, scans)

% map = MapAmplitude(laminarIndex, scans)
%
% Calculate the mean complex amplitude within the specified laminarIndex
% map. This mean is calculated for all of the gray voxels within the input
% laminarIndex array, which specifies the relationship between each
% flatVoxel and its corresponding volume indices. The calculation is
% performed in the GRAY view. Returns the mean amplitude as a matrix with
% the same geometry as the original flat map. Bad values, e.g. from empty
% cells, are flagged as NaNs.
%
% Ress, 05/05

mrGlobals

ampMap = repmat(NaN, size(laminarIndex));

if isempty(selectedFLAT)
  Alert('Select a FLAT')
  return
end
flatView = FLAT{selectedFLAT};
if ~exist('scans', 'var')
  scans = chooseScans(flatView);
end
map = cell(1, numScans(flatView));

if isempty(selectedVOLUME)
  Alert('Select a volume')
  return
end
view = VOLUME{selectedVOLUME};
if ~strcmp(view.viewType, 'Gray')
  view = switch2Gray(view);
  view = loadCorAnal(view);
end
if isempty(view.amp)
  view = loadCorAnal(view);
end


vol = complex(view.anat * 0);
dims = size(vol);
vInds = coords2Indices(view.coords, dims);
ampMap = zeros(size(laminarIndex));

nCells = length(laminarIndex(:));
for iS=1:length(scans)
  scan = scans(iS);
  disp(['Scan ', int2str(scan), '...'])
  waitH = waitbar(0, 'Calculating amplitude map...');
  vol(:) = NaN;
  z = view.amp{scan}.*exp(i*view.ph{scan});
  vol(vInds) = z;
  for ii=1:nCells
    waitbar(ii/nCells, waitH);
    inds = laminarIndex{ii};
    inds = inds(inds > 0);
    if ~isempty(inds)
      ampVals = vol(inds);
      nEmpty = sum(isnan(ampVals));
      if nEmpty > 0
        ok = isfinite(ampVals);
        ampVals = ampVals(ok);
      end
      ampMap(ii) = abs(mean(ampVals));
    end
  end
  map{scan} = ampMap;
  close(waitH)
 
end
flatView = setParameterMap(flatView, map, 'AverageAmplitudes');
saveParameterMap(flatView);
