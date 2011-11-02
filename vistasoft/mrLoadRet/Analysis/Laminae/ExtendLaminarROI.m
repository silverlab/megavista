function laminarCoords = ExtendLaminarROI(depthRange, ROIindex)

% ExtendLaminarROI(depthRange[, ROIindex])
%
% Extend the given ROI coordinates into the specified depthRange,
% a two-vector [min, max], negative values correspond to white matter.
%
% Ress, 10/04

mrGlobals

if isempty(selectedVOLUME)
  Alert('Select a volume')
  return
end
view = VOLUME{selectedVOLUME};

if ~exist('ROIindex', 'var'), ROIindex = view.selectedROI; end

% Calculate laminar dilation range:
dx = mean(view.mmPerVox);
range = [floor(depthRange(1)/dx), ceil(depthRange(2)/dx)];
dThick = diff(range);
t = range(1):0.5:range(2);

% Get the ROI coordinates and bounds:
coords = view.ROIs(ROIindex).coords + dThick;
roiBounds = zeros(3, 2);
for ii=1:3, roiBounds(ii, 1) = min(coords(ii, :)); end
for ii=1:3, roiBounds(ii, 2) = max(coords(ii, :)); end
bDims = diff(roiBounds') + 1;
roiB = roiBounds - dThick;

% Get the mesh, including the surface normals:
[leftPath, nameL] = fileparts(view.leftPath);
leftFile = fullfile(leftPath, '3DMeshes', [nameL, '.MrM']);
if exist(leftFile, 'file'), gMesh.left = mrReadMrM(leftFile, 0); end
[rightPath, nameR] = fileparts(view.rightPath);
rightFile = fullfile(rightPath, '3DMeshes', [nameR, '.MrM']);
if exist(rightFile, 'file'), gMesh.right = mrReadMrM(rightFile, 0); end

% Restrict to ROI bounding box and round vertex locations to nearest integers:
dims = size(view.anat);
if isfield(gMesh, 'left')
  gMesh.left.vertices = gMesh.left.vertices(:, [2 1 3])'; % Convert from mrGray ordering
  gMesh.left.normal = gMesh.left.normal(:, [2 1 3])'; % Convert from mrGray ordering
  for ii=1:3
    indices = find((gMesh.left.vertices(ii, :) >= roiB(ii, 1)) & ...
      (gMesh.left.vertices(ii, :) <= roiB(ii, 2)));
    gMesh.left.vertices = gMesh.left.vertices(:, indices);
    gMesh.left.normal = gMesh.left.normal(:, indices);
  end
  leftCoords = round(gMesh.left.vertices);
  leftIndices = coords2Indices(leftCoords, dims);
  [leftIndices, uInds] = unique(leftIndices);
  leftCoords = leftCoords(:, uInds);
  leftNormals = gMesh.left.normal(:, uInds);
else
  leftCoords = [];
  leftNormals = [];
end
if isfield(gMesh, 'right')
  gMesh.right.vertices = gMesh.right.vertices(:, [2 1 3])'; % Convert from mrGray ordering
  gMesh.right.normal = gMesh.right.normal(:, [2 1 3])'; % Convert from mrGray ordering
  for ii=1:3
    indices = find((gMesh.right.vertices(ii, :) >= roiB(ii, 1)) & ...
      (gMesh.right.vertices(ii, :) <= roiB(ii, 2)));
    gMesh.right.vertices = gMesh.right.vertices(:, indices);
    gMesh.right.normal = gMesh.right.normal(:, indices);
  end
  rightCoords = round(gMesh.right.vertices);
  rightIndices = coords2Indices(rightCoords, dims);
  [rightIndices, uInds] = unique(rightIndices);
  rightCoords = rightCoords(:, uInds);
  rightNormals = gMesh.right.normal(:, uInds);
else
  rightCoords = [];
  rightNormals = [];
end
clear gMesh

% Collect hemispheres, padding coordinates to account for later dilation:
vCoords = [leftCoords, rightCoords] + dThick;
normals = [leftNormals, rightNormals];

% Restrict vertices to ROI. For efficiency, do this in a subvolume that
% includes the ROI and padding to account for the subsequent dilation.
% Step 1: create a map of the vertices
[nn, nVerts] = size(vCoords);
bvCoords = zeros(nn, nVerts);
dbDims = bDims + 2*dThick;
for ii=1:3, bvCoords(ii, :) = vCoords(ii, :) - roiBounds(ii, 1) + dThick + 1; end
vol = repmat(uint8(0), dbDims);
inds = coords2Indices(bvCoords, dbDims);
vol(inds) = 1;
indVol = zeros(dbDims);
for ii=1:nVerts, indVol(bvCoords(1, ii), bvCoords(2, ii), bvCoords(3, ii)) = ii; end
% Step 2: create a map of the ROI, and dilate it to include gray-white
% vertices
bCoords = zeros(size(coords));
for ii=1:3, bCoords(ii, :) = coords(ii, :) - roiBounds(ii, 1) + dThick + 1; end
volR = zeros(dbDims);
indsR = coords2Indices(bCoords, dbDims);
volR(indsR) = 1;
cArr1 = [[0 1 0]; [1 1 1]; [0 1 0]];
cArr = ones(3, 3, 3);
cArr(:, :, 1) = cArr1;
cArr(:, :, 3) = cArr1;
volRd = (convn(volR, cArr, 'same') > 1);
% Step 3: restrict the vertex locations to the ROI:
vol = vol & volRd;
rInds = indVol(find(vol));
rvCoords = bvCoords(:, rInds);
rNormals = normals(:, rInds);

% Dilate ROI vertices along normals
for ii=1:length(t)
  newCoords = round(rvCoords + rNormals*t(ii));
  inds = coords2Indices(newCoords, dbDims);
  vol(inds) = 1;
end
vol = vol | volR; % Always include all voxels in original ROI

% Finally, create the gray classification volume and check for
% contention with gray matter outside of the ROI to avoid growing over
% sulcal boundaries and the like.
% Step 1: Build the classification volume
vDims = size(view.anat) + dThick;
cVol = logical(zeros(vDims));
if ~isempty(view.allLeftNodes)
  inds = coords2Indices(view.allLeftNodes([2 1 3], :)+dThick, vDims);
  cVol(inds) = 1;
end
if ~isempty(view.allRightNodes)
  inds = coords2Indices(view.allRightNodes([2 1 3], :)+dThick, vDims);
  cVol(inds) = 1;
end
% Step 2: Extract the expanded ROI subvolume
eBounds = zeros(3, 2);
eBounds(:, 1) = roiBounds(:, 1) - dThick;
eBounds(:, 2) = roiBounds(:, 2) + dThick;
cVol = cVol(eBounds(1, 1):eBounds(1, 2), eBounds(2, 1):eBounds(2, 2), ...
  eBounds(3, 1):eBounds(3, 2));
% Step 3: Remove ROI gray matter:
cVol(indsR) = 0;
% Step 4: Mask off out-of-ROI gray matter
vol = vol & ~cVol;

% Extract the volume coordinates of the new ROI
laminarCoords = indices2Coords(find(vol), dbDims);
for ii=1:3, laminarCoords(ii, :) = laminarCoords(ii, :) +  roiBounds(ii, 1) - 2*dThick - 1; end

% Remove coordinates that are out-of-range:
tooSmall = any(laminarCoords < 1, 1);
laminarCoords = laminarCoords(:, ~tooSmall);
vDims = size(view.anat);
tooLarge = zeros(1, size(laminarCoords, 2));
for ii=1:3, tooLarge = tooLarge | (laminarCoords(ii, :) > vDims(ii)); end
laminarCoords = laminarCoords(:, ~tooLarge);

% Create the new ROI
name = view.ROIs(ROIindex).name;
newName = ['laminar-', name];
disp(['Creating ROI: ', newName])
view = newROI(view, newName);
newIndex = view.selectedROI;
view.ROIs(newIndex).coords = laminarCoords;
VOLUME{selectedVOLUME} = view;
