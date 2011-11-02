function [ampMap, linds] = CalcThicknessSelectScans(depthRange, nTransverse, linds);

mrGlobals

if isempty(selectedFLAT)
  if isempty(FLAT{1})
    Alert('Select a Flat window!')
    return
  else
    selectedFLAT = 1;
  end
end
view = FLAT{selectedFLAT};
scans = chooseScans(view);
nScans = length(scans);
if nScans == 0, return, end

map = cell(nScans, 1);
thick = cell(nScans, 1);
ratio = cell(nScans, 1);
ampMap = cell(nScans, 1);

if ~exist('linds', 'var')
  linds = MapLaminae(depthRange, nTransverse);
end

disp('Processing functional thickness:');
for iS=1:nScans
  scan = scans(iS);
  disp(['...scan ' int2str(scan)]);
  ampMap{scan} = MapLaminarProfiles(linds, scan);
  map{scan} = FunctionalThicknessMap(ampMap{scan});
end

disp('Processing anatomical thickness...');
thickMap = MapGrayThickness(linds);
for iS=1:nScans
  thick{iS} = thickMap;
  rat = map{iS} ./ thickMap;
  rat(isinf(rat)) = NaN;
  ratio{iS} = rat;
end

view = setParameterMap(view, thick, 'GrayThickness');
saveParameterMap(view);
view = setParameterMap(view, ratio, 'FuncAnatRatio');
saveParameterMap(view);
view = setParameterMap(view, map, 'FunctionalThickness');
FLAT{selectedFLAT} = view;
saveParameterMap(view);

return