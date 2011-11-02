function dist = WhiteDistance(nSize, hemisphere, fName)

% dist = WhiteDistance(nSize, hemisphere, fName);
%
% Calculate the distance map from the white matter for all nodes in
% the volume. Distances into the gray matter are positive, while
% distances into the white matter are negative. Input parameter nSize
% defines the "padding" around the white matter bounding box used in the
% calculation -- default value is 10. Input parameter hemisphere determines
% which segmentation hemisphere's are loaded -- 0 (zero) loads both and is
% the default, 1 (one) loads left only, and 2 loads right only. Input fName
% is an optional classification filename specification that overrides the
% other parameters. 
% 
% Ress, 6/04

mrGlobals

[white, path] = BuildWhiteVolume;
white = permute(white, [2 1 3]);

if exist('nSize', 'var')
  % If nSize parameter is set, perform the calculation only in a
  % bounding-box that surrounds the white matter to save time.
  bbox = round(getfield(regionprops(uint8(white), 'boundingBox'), 'BoundingBox'));
  iMin = bbox([2 1 3]) - nSize;
  iMin(iMin < 1) = 1;
  iMax = bbox([2 1 3]) + bbox([5 4 6]) - 1 + nSize;
  dims = size(white);
  out = find(iMax > dims);
  if ~isempty(out), iMax(out) = dims(out); end
  white = white(iMin(1):iMax(1), iMin(2):iMax(2), iMin(3):iMax(3));
end

% Build distance map from gray-white interface. Distances into gray matter
% are positive, negative into white matter.
% WARNING: interpretation of this calculation depends on isotropy of 
% the voxels. If voxels are not isotropic, either resample the volume so
% that they are, or rewrite this calculation so that it calculates and uses
% the aniostropy.

sDist = repmat(NaN, size(white));

% Step 1: Build an isodensity surface at the gray-white interface, and get
% its vertices:
[f, v] = isosurface(double(white), 0.5);
v = v(:, [2 1 3])';

% Step 2: Calculate distances in the white matter:
whiteInds = find(white);
whiteVerts = indices2Coords(whiteInds, size(white));
[inds, whiteDist] = nearpoints(whiteVerts, v);
sDist(whiteInds) = -sqrt(whiteDist);

% Step 3: Calculate distances in the gray (non-white) matter:
grayInds = find(~white);
grayVerts = indices2Coords(grayInds, size(white));
[inds, grayDist] = nearpoints(grayVerts, v);
sDist(grayInds) = sqrt(grayDist);

if exist('nSize', 'var')
  % Restore subvolume region to full-size array;
  dist = repmat(NaN, dims);
  dist(iMin(1):iMax(1), iMin(2):iMax(2), iMin(3):iMax(3)) = sDist;
  clear sDist white;
end

dist = permute(dist, [2 1 3]);

disp('Saving laminar distance file...')
fName = fullfile(path, 'laminae.mat');
save(fName, 'dist')
