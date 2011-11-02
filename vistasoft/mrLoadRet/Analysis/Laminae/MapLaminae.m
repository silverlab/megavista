function laminarIndices = MapLaminae(depthRange, nTransverse)

% laminarIndices = MapLaminae(depthRange, nTransverse);
%
% Extend the entire mesh into the specified depthRange, a two-vector [min,
% max], negative values correspond to white matter. 
%
% Ress, 10/04

mrGlobals

if isempty(selectedVOLUME)
  Alert('Select a volume')
  return
end
view = VOLUME{selectedVOLUME};
if isempty(selectedFLAT)
  Alert('Select a flat map')
  return
end

% Get the mesh, including the surface normals:
[leftPath, nameL] = fileparts(view.leftPath);
leftFile = fullfile(leftPath, '3DMeshes', [nameL, '.MrM']);
if exist(leftFile, 'file'), mesh.left = mrReadMrM(leftFile, 0); end
[rightPath, nameR] = fileparts(view.rightPath);
rightFile = fullfile(rightPath, '3DMeshes', [nameR, '.MrM']);
if exist(rightFile, 'file'), mesh.right = mrReadMrM(rightFile, 0); end

% Round vertex locations to nearest integers:
dims = size(view.anat);
if isfield(mesh, 'left')
  mesh.left.vertices = round(mesh.left.vertices(:, [2 1 3])'); % Convert from mrGray ordering and round
  mesh.left.normal = mesh.left.normal(:, [2 1 3])'; % Convert from mrGray ordering
  [leftIndices, uInds] = unique(coords2Indices(mesh.left.vertices, dims));
  mesh.left.vertices = mesh.left.vertices(:, uInds);
  mesh.left.normal = mesh.left.normal(:, uInds);
else
  mesh.left.vertices = [];
  mesh.left.normal = [];
end
if isfield(mesh, 'right')
  mesh.right.vertices = round(mesh.right.vertices(:, [2 1 3])') % Convert from mrGray ordering and round
  mesh.right.normal = mesh.right.normal(:, [2 1 3])' % Convert from mrGray ordering
  [rightIndices, uInds] = unique(coords2Indices(mesh.right.vertices, dims));
  mesh.right.vertices = mesh.right.vertices(:, uInds);
  mesh.right.normal = mesh.right.normal(:, uInds);
else
  mesh.right.vertices = [];
  mesh.right.normal = [];
end

% Collect hemispheres
vCoords = [mesh.left.vertices, mesh.right.vertices];
normals = [mesh.left.normal, mesh.right.normal];
clear mesh

% Calculate laminar dilation range:
dx = mean(view.mmPerVox);
range = [floor(depthRange(1)/dx), ceil(depthRange(2)/dx)];
dThick = diff(range);
t = range(1):0.5:range(2);

% Build the gray-classification volume
vDims = size(view.anat);
cVol = logical(view.anat*0);
if ~isempty(view.allLeftNodes)
  inds = coords2Indices(view.allLeftNodes([2 1 3], :), vDims);
  cVol(inds) = 1;
end
if ~isempty(view.allRightNodes)
  inds = coords2Indices(view.allRightNodes([2 1 3], :), vDims);
  cVol(inds) = 1;
end

% Build dilation kernel:
cArr1 = [[0 1 0]; [1 1 1]; [0 1 0]];
cArr = ones(3, 3, 3);
cArr(:, :, 1) = cArr1;
cArr(:, :, 3) = cArr1;

% Loop over flat map:
flatDims = size(FLAT{selectedFLAT}.anat);
laminarIndices = cell(flatDims);
iMin = 1 + floor(nTransverse/2);
iMax = flatDims(2) - floor(nTransverse/2);
jMax = flatDims(1) - floor(nTransverse/2);
waitH = waitbar(0, 'Mapping laminar coordinates...');
hemis = find([~isempty(FLAT{selectedFLAT}.coords{1}), ~isempty(FLAT{selectedFLAT}.coords{2})]);
nHemis = length(hemis);
for kFlat=hemis;
  for jFlat=iMin:jMax
    waitbar(kFlat*jFlat/jMax/nHemis, waitH);
    for iFlat=iMin:iMax
      coords = CreateFlatGrayROI(FLAT{selectedFLAT}, [jFlat; iFlat; kFlat], nTransverse);
      if length(coords(:)) >= 6
        roiBounds = [min(coords'); max(coords')]';
        bDims = diff(roiBounds') + 1;
        % Delimit mesh coordinates to ROI vicinity:
        indices = find((vCoords(1, :) >= roiBounds(1, 1)) & (vCoords(1, :) <= roiBounds(1, 2)));
        svCoords = vCoords(:, indices);
        svNormals = normals(:, indices);
        for ii=2:3
          indices = find((svCoords(ii, :) >= roiBounds(ii, 1)) & (svCoords(ii, :) <= roiBounds(ii, 2)));
          svCoords = svCoords(:, indices);
          svNormals = normals(:, indices);
        end
        
        % Create a subvolume that includes the ROI and padding to account
        % for the subsequent dilation
        % Step 1: create a map of the vertices
        [nn, nVerts] = size(svCoords);
        bvCoords = zeros(nn, nVerts);
        bDims = diff(roiBounds') + 1;
        dbDims = bDims + 2*dThick;
        for ii=1:3, bvCoords(ii, :) = svCoords(ii, :) - roiBounds(ii, 1) + dThick + 1; end
        vol = repmat(uint8(0), dbDims);
        vol(coords2Indices(bvCoords, dbDims)) = 1;
        indVol = zeros(dbDims);
        for ii=1:nVerts, indVol(bvCoords(1, ii), bvCoords(2, ii), bvCoords(3, ii)) = ii; end
        % Step 2: create a map of the ROI, and dilate it to include gray-white
        % vertices
        bCoords = zeros(size(coords));
        for ii=1:3, bCoords(ii, :) = coords(ii, :) - roiBounds(ii, 1) + dThick + 1; end
        volR = zeros(dbDims);
        indsR = coords2Indices(bCoords, dbDims);
        volR(indsR) = 1;
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
        
        % Finally, check for contention with gray matter outside of the ROI to
        % avoid growing over sulcal boundaries and the like.
        % Step 1: Extract the expanded ROI subvolume
        eBounds = zeros(3, 2);
        eBounds(:, 1) = roiBounds(:, 1) - dThick;
        delta0 =  1 - eBounds(:, 1);
        delta0(delta0 < 0) = 0;
        eBounds(delta0 > 0, 1) = delta0(delta0 > 0);
        eBounds(:, 2) = roiBounds(:, 2) + dThick;
        delta1 = eBounds(:, 2) - vDims';
        delta1(delta1 < 0) = 0;
        eBounds(delta1 > 0, 2) = vDims(delta1 > 0);
        cVola = cVol(eBounds(1, 1):eBounds(1, 2), eBounds(2, 1):eBounds(2, 2), ...
          eBounds(3, 1):eBounds(3, 2));
        % If the subvolume exceeds the boundaries of the original
        % classification volume, pad the result with zeros
        cVol1 = vol * 0;
        cVol1(1+delta0(1):dbDims(1)-delta1(1), 1+delta0(2):dbDims(2)-delta1(2), ...
          1+delta0(3):dbDims(3)-delta1(3)) = cVola;
        % Step 2: Remove ROI gray matter:
        cVol1(indsR) = 0;
        % Step 3: Mask off out-of-ROI gray matter
        vol = vol & ~cVol1;
        
        % Extract the volume coordinates and convert to indices
        laminarCoords = indices2Coords(find(vol), dbDims);
        for ii=1:3, laminarCoords(ii, :) = laminarCoords(ii, :) +  roiBounds(ii, 1) - dThick - 1; end
        laminarIndices{jFlat, iFlat} = coords2Indices(laminarCoords, vDims);
      end
    end
  end
end

close(waitH)