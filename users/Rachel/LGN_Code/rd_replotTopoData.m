% rd_replotTopoData.m
%
% Given a previously saved brain slice map, replot it, making any changes
% you want.
%
% Modified from end of rd_plotTopographicData2SatFn.m
%
% Rachel Denison
% 2012 Sept 16

% (first load BrainMapTopo file)

hemi = 2;
name = 'betaP';

% load map data
mapFiles = dir(sprintf('lgnROI%dBrainMap*_%s_*', hemi, name));
if numel(mapFiles)~=1
    error('Too many or too few map files.')
else
    load(mapFiles.name);
end

mapFileBase = sprintf('lgnROI%dBrainMapTopoCoronalReorient_', hemi);
mapSavePath = sprintf('%s%s_%s_%s%s', mapFileBase, name, voxDescrip, satDescrip, datestr(now,'yyyymmdd'));

nSlices = numel(brainSliceMaps);
nPlotCols = ceil(sqrt(nSlices));
nPlotRows = ceil(nSlices/nPlotCols);

slicePlotOrder = nSlices:-1:1;
saveFigs = 1;

f = figure('name', mapName);
for iSlice = 1:nSlices

    slice = slicePlotOrder(iSlice);
    
    % get RGB map for this slice
    brainSliceMap = brainSliceMaps{slice};
    
    % transform map as you like
    for iRGB = 1:3
        mapXFormed(:,:,iRGB) = fliplr(imrotate(brainSliceMap(:,:,iRGB),90));
    end
    
    % show slice with colored map
    subplot(nPlotRows, nPlotCols, iSlice)
    image(mapXFormed)
    title(sprintf('Slice %d', slice))
    axis off
    
end

if saveFigs
    print(f,'-djpeg',sprintf('figures/%s', mapSavePath));
end