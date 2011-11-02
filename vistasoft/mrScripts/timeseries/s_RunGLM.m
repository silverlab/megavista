%% s_RunGLM
%
% Illustrates how to run a GLM on a functional data set
%
% You might set up a path file that includes vistadata on your path, and
% you might call it vistaDataPath 
%
% Stanford VISTA

%% Initialize the key variables and data path:
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');
parfDir = fullfile(dataDir, 'Stimuli', 'parfiles');

% There can be several data types - we're using motion compensated dated
dataType = 'MotionComp';

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set data structure properties:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Prepare scans for GLM:
numScans = viewGet(vw, 'numScans');
whichScans = 1:numScans;

% If you're processing your own experiment, you'll need to produce parfiles
% More info @
% http://white.stanford.edu/newIm/index.php/GLM#Create_.par_files_for_each_scan
whichParfs = {'VWFALocalizer1_jw_11-Mar-2009.par' ...
              'VWFALocalizer2_jw_11-Mar-2009.par' ...
              'VWFALocalizer3_jw_11-Mar-2009.par'};

vw = er_assignParfilesToScans(vw, whichScans, whichParfs); % Assign parfiles to scans
vw = er_groupScans(vw, whichScans, [], dataType); % Group scans together

%% Set GLM Parameters:
% More info @
% http://white.stanford.edu/newIm/index.php/MrVista_1_conventions#eventAnalysisParams
params.timeWindow               = -8:24;
params.bslPeriod                = -8:0;
params.peakPeriod               = 4:14;
params.framePeriod              = 2; % TR
params.normBsl                  = 1;
params.onsetDelta               = 0;
params.snrConds                 = 1;
params.glmHRF                   = 2;
params.eventsPerBlock           = 6;
params.ampType                  = 'betas';
params.detrend                  = 1;
params.detrendFrames            = 20;
params.inhomoCorrect            = 1;
params.temporalNormalization    = 0;
params.glmWhiten                = 0;

saveToDataType = 'GLMs'; % Data type the results will be saved to

%% Run GLM:
% Returns view structure and saved-to scan number in new data type
[vw, newScan] = applyGlm(vw, dataType, whichScans, params, saveToDataType);

%% Should you want to delete the GLM you most recently ran, run:
removeScan(vw, newScan, saveToDataType, 1);

%% END











