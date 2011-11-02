function val = v_viewGetInplane
%Validate various calls to viewGet in the Inplane view. 
%   val = v_viewGetInplane
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
mrVista; 
vw = getSelectedInplane;
mrGlobals;

%% Set data structure properties:
vw = viewSet(vw, 'current dt', 1); 
vw = viewSet(vw, 'current scan', 1); 
vw = viewSet(vw, 'current slice', 10);

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

% subject
val.subject         =  length(viewGet(vw, 'subject'));

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

% subject 
val.subject         =  length(viewGet(vw, 'subject'));

% current scan 
val.curscan         =  viewGet(vw, 'curscan');

% current slice
val.curslice         =  viewGet(vw, 'current slice');

% n scans
val.nscans         =  viewGet(vw, 'num scans');

% n slices
val.nslices        =  viewGet(vw, 'num slices');

% montage slices
val.montageslices  =  viewGet(vw, 'montage slices');

% dt name
val.dtname         =  length(viewGet(vw, 'dt name'));

% curdt
val.curdt          =  viewGet(vw, 'current dt');

% dtstruct
val.dtstruct       =  numel(fieldnames(viewGet(vw, 'dtstruct')));


cd(curDir)

f = viewGet(vw, 'fignum');
close(f);

return

%% NYI
% coherence
val.coherence       =  viewGet(vw, 'coherence');



%         %%%%% Traveling-Wave / Coherence Analysis properties
%     'coherence' 
%     'scanco'
%     'phase'
%     'scanph'
%     'amplitude'
%     'scanamp'
%     'refph'
%     'ampmap'
%     'coherencemap'
%     'correlationmap'
%     'cothresh'
%     'phwin'       
%         %%%%% colorbar-related params: this code uses a simple linear
%         %%%%% mapping from coAnal phase -> polar angle or eccentricity
%     'twparams' 
%     'cmap'
%     'cmapcolor'
%     'cmapgrayscale'
%         
%         %%%%% Map properties
%     'map'
%     'mapwin'
%     'mapname'
%     'mapunits'
%     'mapclip'
%     'scanmap' 
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
%     'datavalindex'
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
% vFile = fullfile(mrvDataRootPath,'validate','viewGetInplane');
% stored = load(vFile);
% save(vFile, '-struct', 'val');



%% End Script




