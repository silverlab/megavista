function test_tSeries4D
%
% Validate loading a time series from a functional data set.
%
% Tests: loadtseries, percentTseries, tSeries4D
%
% Stanford VISTA
%

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to plot
dataType = 'MotionComp';

% Which scan number from that data type?
scan = 1;

% Would you like the raw time series?
isRawTSeries = true;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set data structure properties:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Get time series from ROI:
% Format returned is rows x cols x slices x time
tSeries = tSeries4D(vw, scan, [], 'usedefaults', isRawTSeries);

% This is the validation file
vFile = fullfile(mrvDataRootPath,'validate','tSeries4D');
storedTSeries = load(vFile);

% Get back to the testing directory: 
cd(curDir)


assertEqual(storedTSeries.dim, size(tSeries));

assertEqual(storedTSeries.mn, mean(double(tSeries(:))));

assertEqual(storedTSeries.sd, std(double(tSeries(:))));

%% End Script




