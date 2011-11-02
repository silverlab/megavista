%% s_LoadTSeries
%
% Illustrates how to load a time series from a functional data set
%
% You might set up a path file that includes vistadata on your path, and
% you might call it vistaDataPath 
%
% Stanford VISTA

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','prfInplane');

% There can be several data types - name the one you want to plot
dataType = 'Original';

% An ROI currently located in the ROIs directory of the relevant dataType
roiName  = 'LV1';

% Which scan number from that data type?
scan = 1;

% Would you like the raw time series?
isRawTSeries = false;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set data structure properties:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type
vw = viewSet(vw, 'ROI', roiName); % Region of interest

%% Get time series from ROI:
tSeries = tSeries4D(vw, scan, [], 'usedefaults', ~isRawTSeries);

%% END
