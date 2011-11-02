function val = v_tSeries4D
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
isRawTSeries = false;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set data structure properties:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Get time series from ROI:
% Format returned is rows x cols x slices x time
tSeries = tSeries4D(vw, scan, [], 'usedefaults', ~isRawTSeries);

val.dim = size(tSeries);
val.mn  = mean(double(tSeries(:)));
val.sd =  std(double(tSeries(:)));

% This is the validation file
% vFile = fullfile(mrvDataRootPath,'validate','tSeries4D');
% stored = load(vFile);
% save(vFile, '-struct', 'val');


cd(curDir)

%% End Script




