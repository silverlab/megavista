function val = v_viewGetHidden
%Validate various calls to viewGet in the hidden inplane view. 
%   val = v_viewGetHidden
%
% Notes:
%   At the bottom of this function is a list of all viewGet calls that have
%   not yet been implemented in this function. Eventually we would like to
%   implement (i.e, validate) all cases that apply to INPLANE views.
%
%   To make life simple, we would like a number (or numbers) returned from
%   every call. Hence for calls that return text or cell arrays, we
%   calculate some simple statistic like the length of the array.
%
%   Some calls to viewGet, such as 'current scan' and 'current slice' can
%   change if the user has saved preferences with these values. This can
%   happen surreptitously if vista prefs are set to always save preferences
%   upon closing a session. Therefore, we first set the value of these
%   fields before proceeding to the viewGets.  For fields such as 'subject'
%   or 'number of frames' which will not change, we do not use a viewSet.
%
%
% Tests: viewSet, viewGet
%
% Stanford VISTA
%

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Get data structure:
vw = initHiddenInplane; 
mrGlobals;

%% Set data structure properties:
vw = viewSet(vw, 'current dt', 1); 
vw = viewSet(vw, 'current scan', 1); 

%%
% Home Directory
[pth, tmp]  = fileparts(viewGet(vw, 'Home Directory')); %#ok<ASGLU>
val.homedir = length(tmp);

% session name
val.sessionName     = length(viewGet(vw, 'session name'));

% subject
val.subject         =  length(viewGet(vw, 'subject'));

% name
val.name            =  length(viewGet(vw, 'name'));

% annotation
%   This is empty in the sample data set so we must set it first
dt   = viewGet(vw, 'dt struct');
dt = dtSet(dt, 'annotation', 'my first scan', 1);
dt = dtSet(dt, 'annotation', 'my second scan', 2);
dt = dtSet(dt, 'annotation', 'my third scan', 3);
dtnum = viewGet(vw, 'current dt');
dataTYPES(dtnum) = dt;
val.annotation      =  length(viewGet(vw, 'annotation', 1));

% annotations
val.annotations     =  numel(viewGet(vw, 'annotations'));

% viewtype
val.viewtype        =  length(viewGet(vw, 'View Type'));

% subdir 
val.subdir          =  length(viewGet(vw, 'subdir'));

% current scan 
val.curscan         =  viewGet(vw, 'curscan');

% current slice (empty in hidden view)
val.curslice         =  viewGet(vw, 'current slice');

% n scans
val.nscans         =  viewGet(vw, 'num scans');

% n slices
val.nslices        =  viewGet(vw, 'num slices');

% montage slices  (empty in hidden view)
val.montageslices  =  viewGet(vw, 'montage slices');

% dt name
val.dtname         =  length(viewGet(vw, 'dt name'));

% curdt
val.curdt          =  viewGet(vw, 'current dt');

% dtstruct
val.dtstruct       =  numel(fieldnames(viewGet(vw, 'dtstruct')));

% coranal fields...
vw = loadCorAnal(vw);

% coherence
tmp       =  viewGet(vw, 'coherence');
val.coherence = nanmean(tmp{1}(:));

% scanco
tmp       =  viewGet(vw, 'scanco');
val.scanco = nanmean(tmp(:));

% phase
tmp       =  viewGet(vw, 'phase');
val.phase = nanmean(tmp{1}(:));

% scanph
tmp       =  viewGet(vw, 'scanph');
val.scanph = nanmean(tmp(:));

% amplitude
tmp       =  viewGet(vw, 'amplitude');
val.amplitude = nanmean(tmp{1}(:));

% scanph
tmp       =  viewGet(vw, 'scanamp');
val.scanamp = nanmean(tmp(:));

%refph
vw = viewSet(vw, 'reference phase', pi);
val.refph = viewGet(vw, 'reference phase');

%colormaps: NA for hidden views. If we implement v_viewGetINPLANE we can
%           use this bit of code.
%   val.ampmap = viewGet(vw, 'ampmap');
%   val.comap  = viewGet(vw, 'coherencemap');
%   val.cormap = viewGet(vw, 'correlationmap');
%   val.cmap   = viewGet(vw, 'cmap');
%   val.cmapcolor   = viewGet(vw, 'cmapcolor');
%   val.cmapgrayscale   = viewGet(vw, 'cmapgrayscale');


% cothresh
vw = viewSet(vw, 'cothresh', .1);
val.cothresh = viewGet(vw, 'cothresh');

% phasewin
vw = viewSet(vw, 'phasewin', [pi/4 3*pi/4]);
val.phasewin = viewGet(vw, 'phasewin');

% twparams - empty because travelling wave params are not set in this session
val.twparams = viewGet(vw, 'twparams');

% map properties
% scan = 1; forceSave = -1; % -1 = don't save at all
% vw = computeMeanMap(vw, scan, forceSave);
vw=loadMeanMap(vw);

% map
tmp       =  viewGet(vw, 'map');
val.map = nanmean(tmp{1}(:));

% scanmap
tmp       =  viewGet(vw, 'scanmap');
val.scanmap = nanmean(tmp(:));

% mapwin
val.mapwin =  viewGet(vw, 'mapwin');

% mapname
val.mapname =  length(viewGet(vw, 'mapname'));

% map units (empty in mean map)
val.mapunits =  length(viewGet(vw, 'mapunits'));

% map clip (empty in hidden view)
val.mapclip =  viewGet(vw, 'mapclip');

%     ''

%%
cd(curDir)

return

%% NYI

    
%         %%%%% Anatomy / Underlay-related properties
%     'anatomy'
%     'anatomymap'
%     'anatclip'
%     'anatsize'
%     'anatsizexyz'
%     'brightness'
%     'contrast'
%     'mmpervox'
%     'ngraylayers'
%     'scannerxform'
%     'b0dir'
%     'b0angle'
%         %%%%% ROI-related properties
%     'rois'
%     'roistruct'
%     'roicoords'
%     'roiindices'
%     'roivertinds'val.coherence         =  viewGet(vw, 'coherence')
%     'roiname'
%     'allroinames'
%     'selectedroi'
%     'filledperimeter'
% 	  'selroicolor'
%     'prevcoords'
%     'roistodisplay'
%     'roidrawmethod'
%     'showrois'
%     'hidevolumerois'
%     'maskrois'
%         %%%%% Time-series related properties
%     'tseriesdir'
%     'datasize'
%     'dim'
%     'tseries'
%     'tseriesslice'
%     'tseriesscan'
%     'tr'
%     'nframes'
%     'ncycles'
%         %%%%% Retinotopy/pRF Model related properties    
%     'framestouse'
%     'rmfile'
%     'rmmodel'
%     'rmcurrent'
%     'rmmodelnames'
%     'rmparams'
%     'rmstimparams'
%     'rmmodelnum'
%     'rmhrf'
%         %%%%% Mesh-related properties
%     'allmeshes'
%     'allmeshids'
%     'mesh'
%     'currentmesh'
%     'meshn'
%     'meshdata'
%     'nmesh'
%     'meshnames'
%     'meshdir'        
%         %%%%% Volume/Gray-related properties
%     'nodes'
%     'xyznodes'
%     'nodegraylevel'
%     'nnodes'
%     'edges'
%     'nedges'
%     'allleftnodes'
%     'allleftedges'
%     'allrightnodes'
%     'allrightedges'
%     'coords'
%     'coordsfilename'
%     'ncoords'           
%     'classfilename'
%     'classdata'
%     'graymatterfilename'        
%         %%%%% EM / General-Gray-related properties
%     'datavalindex'val.scanmap = nanmean(tmp(:))
%     'analysisdomain'      
%         %%%%% Flat-related properties
%     'graycoords'
%     'leftpath'
%     'rightpath'
%     'fliplr'
%     'imagerotation'
%     'hemifromcoords'
%     'roihemi'
% %%%%% UI properties
%     'ishidden'
%     'ui'
%     'fignum'
%     'windowhandle'
%     'displaymode'
%     'anatomymode'
%     'coherencemode'
%     'correlationmode'
%     'phasemode'
%     'amplitudemode'
%     'projectedamplitudemode'
%     'mapmode'
%     'zoom'
%     'crosshairs'
%     'locs'
%     'phasecma'
%     'cmapcurrent'
%     'cmapcurmodeclip'
%     'cmapcurnumgrays'
%     'cmapcurnumcolors'
%     'flipud'

% This is the validation file
% vFile = fullfile(mrvDataRootPath,'validate','viewGetHidden');
% stored = load(vFile);
% save(vFile, '-struct', 'val');



%% End Script




