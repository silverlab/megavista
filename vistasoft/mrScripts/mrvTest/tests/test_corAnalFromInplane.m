function test_corAnalFromInplane
%
% Validate calculation of coranal.
%
% Tests: computeCorAnalSeries
%
% Stanford VISTA
%


%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');

% This is the validation file
vFile = fullfile(mrvDataRootPath,'validate','coranalFromInplane');
storedCorAnal = load(vFile);

% These are the items we storedCorAnal in the validation file
%
% val.dim    = size(coSeries);
% val.comn   = nanmean(coSeries);
% val.ampmn  = nanmean(ampSeries);
% val.phmn   = nanmean(phSeries);
% val.comax  = nanmax(coSeries);
% val.ampmax = nanmax(ampSeries);
% val.phmax  = nanmax(phSeries);
% save(vFile, '-struct', 'val')


%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% There can be several data types - name the one you want to plot
dataType = 'Original';

% Which scan number from that data type?
scan = 1;
% Which slice number?
slice = 1;

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set dataTYPE:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Get time series from ROI:
% Get the number of cycles for the block design
nCycles = viewGet(vw, 'nCycles', scan);

% calculate the coranal
[coSeries,ampSeries,phSeries] = ...
    computeCorAnalSeries(vw, scan, slice, nCycles);

cd(curDir)
assertEqual(storedCorAnal.dim, size(coSeries));

assertEqual(storedCorAnal.comn,nanmean(coSeries));

assertEqual(storedCorAnal.ampmn, nanmean(ampSeries));

assertEqual(storedCorAnal.phmn, nanmean(phSeries));
assertEqual(storedCorAnal.comax, max(coSeries));
assertEqual(storedCorAnal.ampmax, max(ampSeries));
assertEqual(storedCorAnal.phmax, max(phSeries));


%% End Script




