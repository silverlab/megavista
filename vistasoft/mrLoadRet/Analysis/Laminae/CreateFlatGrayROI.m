function coords = CreateFlatGrayROI(view, coord, nTransverse)

% coords = CreateFlatGrayROI(view, flatCoord, nTransverse);
%
% Collect all the volume coordinates that correspond to the input flat-map
% coordinate, which is dilated to a square neighborhood of size
% nTraverse.
%
% Ress, 11/04

nHalf = floor(nTransverse/2);

flatDims = size(view.anat);
flatInds = coords2Indices(round(view.coords{coord(3)}), flatDims(1:2));
coords = [];
for jj=-nHalf:nHalf
  for ii=-nHalf:nHalf
    cc = coord(1:2) + [jj; ii];
    ind = coords2Indices(cc, flatDims(1:2));
    coords = [coords, view.grayCoords{coord(3)}(:, ind == flatInds)];
  end
end
    