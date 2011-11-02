function val = v_coranalFromInplane
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
% vFile = fullfile(mrvDataRootPath,'validate','coranalFromInplane');
% stored = load(vFile);

% These are the items we stored in the validation file
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

% Compute summary statistics        
val.dim    = size(coSeries);
val.comn   = nanmean(coSeries);
val.ampmn  = nanmean(ampSeries);
val.phmn   = nanmean(phSeries);
val.comax  = max(coSeries);
val.ampmax = max(ampSeries);
val.phmax  = max(phSeries);

cd(curDir)

%% End Script




