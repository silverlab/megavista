function vw  = smMakePCMap(model, PCnum, vw)
% vw = smMakeParameterMap(model, PCnum, vw);

%----------------------------------------
% var check
if notDefined('model'), error('[%s]: Need a model', mfilename); end
if notDefined('vw'),    vw = getCurView; end
if notDefined('PCnum'), 
    PCnum = 1; 
    warning('[%s]: PC not specified. Defaulting to PC 1.', mfilename); 
end
%----------------------------------------

% get the gray node indices of the predictor ROI
grayCoords = viewGet(vw, 'coords');
roiXcoords = smGet(model, 'roiXcoords');
[foo foo roiXindices] = intersectCols(roiXcoords, grayCoords);

% set map for first scan to zeros, and delete maps for other scans
n = size(vw.coords,2);
map = cell(1);
map{1} = zeros(1,n);

% put the weights into the map
PCcoeffs = smGet(model, 'PCcoeff', PCnum);
map{1}(roiXindices) = PCcoeffs;

%name the map
mapName = [smGet(model, 'roiXname') ' PC ' num2str(PCnum)];

% load it into the view
vw =  setParameterMap(vw,map,mapName, 'PC weights');
vw =  setDisplayMode(vw,'map');

% clip the map to the min and max values 
mapwin =  [-max(abs(PCcoeffs)) max(abs(PCcoeffs))];
vw =  viewSet(vw,'mapwin', mapwin);
vw =  viewSet(vw,'mapclipmode', mapwin);

%vw.ui.mapMode=setColormap(vw.ui.mapMode, 'jetCmap');
    
vw =  refreshScreen(vw);

return


    