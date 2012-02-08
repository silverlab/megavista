function vals = rd_spmGetValsFromImgAtCoords(imfile, vXYZ)

im = readFileNifti(imfile);
sz = size(im.data);
idxs = sub2ind(sz, vXYZ(1,:), vXYZ(2,:), vXYZ(3,:));
vals = im.data(idxs);