function view = computeMeanMap(view,scanList,forceSave)
% Computing the mean functional image for each tSeries
%
%  view = computeMeanMap(view,[scanList],[forceSave])
%
% The mean functional images are combined into a parameter map and
% calls setParameterMap to set view.map = meanMap.
%
% scanList: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
%
% forceSave: 1 = true (overwrite without dialog)
%            0 = false (query before overwriting)
%           -1 = do not save
%
% If you change this function make parallel changes in:
%    computeCorAnal, computeResStdMap, computeStdMap
%
% djh, 12/30/98
% djh, 2/22/2001 updated to version 3
% ras, 01/05, added forceSave flag
% ras 10/05, checks if the meanMap file is saved already

if notDefined('forceSave'), forceSave = 0; end

% nScans = numScans(view);
nScans = viewGet(view,'numscans');

if strcmp(view.mapName,'meanMap')
    % If exists, initialize to existing map
    map=view.map;
elseif exist(fullfile(dataDir(view),'meanMap.mat'),'file')
    % load from the mean map file
    load(fullfile(dataDir(view),'meanMap.mat'),'map')    
else
    % Otherwise, initialize to empty cell array
    map = cell(1,nScans);
end

% (Re-)set scanList
if ~exist('scanList','var')
    scanList = er_selectScans(view);
elseif scanList == 0
    scanList = 1:nScans;
end
if isempty(scanList),  error('Analysis aborted'); end

% Compute it
waitHandle = waitbar(0,'Computing mean images from the tSeries.  Please wait...');
ncScans = length(scanList);
for iScan = 1:ncScans
    scan = scanList(iScan);
    dims = viewGet(view, 'sliceDims', scan);
    map{scan} = NaN*ones(dataSize(view,scan));
    for slice = sliceList(view,scan)
        tSeries = loadtSeries(view,scan,slice);
        nValid = sum(isfinite(tSeries));
        tSeries(isnan(tSeries(:))) = 0;

        % if there is one time point, we will have problems, so duplicate
        % the data
        if size(tSeries,1) == 1,
            tSeries = repmat(tSeries, 3, 1);
            nValid = sum(isfinite(tSeries));
        end

        tmp = sum(tSeries) ./ nValid;
        if strcmp(view.viewType,'Inplane')
            map{scan}(:,:,slice) = reshape(tmp,dims);
        else
            map{scan}(:,:,slice) = tmp;
        end
    end
    waitbar(scan/ncScans)
end
close(waitHandle);

% Set Parameter MAp
view = setParameterMap(view, map, 'meanMap');

% Save file
if forceSave >= 0, saveParameterMap(view, [], forceSave); end

return
