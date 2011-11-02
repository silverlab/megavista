function thickMap = MapStructuralThickness;

% thickMap = MapStructuralThickness([laminarIndices]);
%
% Map the structural thickness by averaging previouly calculated gray
% thickness values with respect to the current laminarCoordinates.
%
% Ress, 07/05

mrGlobals

if exist('vANATOMYPATH', 'var') & ~isempty(vANATOMYPATH)
  path = fileparts(vANATOMYPATH);
else
  path = uigetdir('', 'Select anatomy directory');
end

thickFile = fullfile(path, 'thickness.mat');
if exist(thickFile, 'file')
  load(thickFile);
else
  yn = questdlg('No anatomy thickness file. Perform lengthy thickness calculation?');
  if ~strcmp(yn, 'Yes'), return, end
  thickness = mrmCalcGrayThickness;
  if isempty(thickness), return, end
end

% Get the current VOLUME view, and make sure it is in Gray mode:
if isempty(selectedVOLUME)
  view = initHiddenVOLUME;
  view = switch2Gray(view);
else
  view = VOLUME{selectedVOLUME};
end
if ~strcmp(view.viewType, 'Gray'), view = switch2Gray(view); end
if isempty(view.anat), view = loadAnat(view); end
vDims = size(view.anat);
dx = mean(view.mmPerVox);

% Get the layer-1 gray nodes:
if isempty(view.allLeftNodes)
  inds = [];
  L1Verts = [];
  layers = [];
else
  L1Verts = view.allLeftNodes([2 1 3], view.allLeftNodes(6, :) == 1);
  inds = coords2Indices(view.allLeftNodes([2 1 3], :), vDims);
  layers = uint8(view.allLeftNodes(6, :));
end
if ~isempty(view.allRightNodes)
  L1Verts = [L1Verts, view.allRightNodes([2 1 3], view.allRightNodes(6, :) == 1)];
  inds = coords2Indices(view.allRightNodes([2 1 3], :), vDims);
  layers = [layers, uint8(view.allRightNodes(6, :))];
end

% Map the thickness values into the volume:
inds = coords2Indices(L1Verts, vDims);
anat = repmat(uint8(0), vDims);
anat(inds) = uint8(thickness);

% Create layer-index look-up table:
iVol = repmat(uint8(0), vDims);
for ii=1:length(inds), iVol(inds(ii)) = layers(ii); end

if ~isfield(view, 'laminarIndices'), LoadLaminarIndices; end
nVerts = length(view.laminarIndices);
thickMap = repmat(NaN, 1, nVerts);
% Loop over the laminar coordinates to get average thickness:
nVerts = length(view.laminarIndices);
wH = waitbar(0, 'Averaging thickness along layer 1...');
for ii=1:nVerts
  waitbar(ii/nVerts, wH);
  inds1 = view.laminarIndices{ii};
  iLayers = iVol(inds1);
  inds1 = inds1(iLayers == 1);
  thickVals = anat(inds1);
  thickMap(ii) = dx * mean(thickVals(thickVals > 0));
end

close(wH);

return