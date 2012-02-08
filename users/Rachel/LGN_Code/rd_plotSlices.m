function f = rd_plotSlices(im)
%
% assumes 3rd dimension is slices

nSlices = size(im,3);
nCols = ceil(sqrt(nSlices));
nRows = ceil(nSlices/nCols);

f = figure;
for iSlice = 1:nSlices
    subplot(nRows,nCols,iSlice)
    imagesc(im(:,:,iSlice))
    colormap gray
    axis off
    axis equal
end