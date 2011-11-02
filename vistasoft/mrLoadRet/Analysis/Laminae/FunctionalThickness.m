function [maps, linds, ampMap] = FunctionalThickness(ampThresh, scan, scanS)

% [mapStructure, linds, ampMap] = FunctionalThickness([ampThresh, scan, scanS]);
% 
% Performs laminar analysis and functional thickness analysis of the
% current session. Returns a structure containing mapping data (functional
% and structural thickness), and laminar analysis data, linds and ampMap.
%
% Ress, 

mrGlobals

maps = []; linds = []; ampMap = [];

if ~exist('VOLUME', 'var'), return, end
if ~exist('ampThresh', 'var'), ampThresh = 0.1; end
if ~exist('scan', 'var'), scan = getCurScan(VOLUME{selectedVOLUME}); end

% Map amplitude profiles:
LoadLaminarIndices;
if ~isfield(VOLUME{selectedVOLUME}, 'laminarIndices'), return, end
VOLUME{selectedVOLUME} = switch2Vol(VOLUME{selectedVOLUME});
VOLUME{selectedVOLUME} = loadCorAnal(VOLUME{selectedVOLUME});
ampMap = MapLaminarProfiles;
linds = VOLUME{selectedVOLUME}.laminarIndices;
save laminarMaps linds ampMap

% Create layer-1 maps:
VOLUME{selectedVOLUME} = switch2Gray(VOLUME{selectedVOLUME});
fMap = FunctionalThicknessMap(ampMap);
sMap = MapStructuralThickness;
L1inds = find(VOLUME{selectedVOLUME}.nodes(6,:)==1);
mapF = repmat(NaN, 1, size(VOLUME{selectedVOLUME}.coords, 2));
mapF(L1inds) = fMap;
mapS = repmat(NaN, 1, size(VOLUME{selectedVOLUME}.coords, 2));
mapS(L1inds) = sMap;
maxAmp = zeros(size(L1inds));
for ii=1:length(maxAmp)
  if ~isempty(ampMap{ii}), maxAmp(ii) = max(ampMap{ii}(1, :)); end
end
maps.funcMapL1 = fMap;
maps.funcMap = mapF;
maps.strucMapL1 = sMap;
maps.strucMap = mapS;
maps.maxAmp = maxAmp;
maps.inds = L1inds;
maps.session = mrSESSION;
save thickMaps maps

% Plot results:
good = find(isfinite(sMap) & isfinite(fMap) & maxAmp > ampThresh);
nGood = length(good);
fMap1 = [zeros(1, nGood*5), fMap(good)];
sMap1 = [zeros(1, nGood*5), sMap(good)];
figure; plot(sMap1, fMap1, '.', 0:4, 0:4, 'k'); axis([0 4 0 4]); axis square
xlabel('Structural thickness (mm)'); ylabel('Functional thickness (mm)');

% Make maps if selected
if ~ieNotDefined('scanS')
  map = cell(1, numScans(VOLUME{selectedVOLUME}));
  map{scan} = mapF;
  map{scanS} = mapS;
  if scan < scanS
    name = 'FuncStrucMaps';
  else
    name = 'StrucFuncMaps';
  end
  VOLUME{selectedVOLUME} = setParameterMap(VOLUME{selectedVOLUME}, map, name);
  saveParameterMap(VOLUME{selectedVOLUME});
  VOLUME{selectedVOLUME}.ui.mapMode.clipMode = [0 4];
  VOLUME{selectedVOLUME} = refreshView(VOLUME{selectedVOLUME});
  VOLUME{selectedVOLUME} = loadCorAnal(VOLUME{selectedVOLUME});
  
end

return
