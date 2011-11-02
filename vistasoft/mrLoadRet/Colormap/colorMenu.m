function view=colorMenu(view)
% 
% view=colorMenu(view)
% 
% ras 05/30/04: added option to set clip modes for each view mode
% Importing and Exporting / AAB,  BW

cmmenu = uimenu('Label', 'Color Map', 'Separator', 'on', ...
    'ForegroundColor', [0.0 0.0 1.0]);

% Reset Defaults callback:
%  view=resetDisplayModes(view);
%  view=refreshScreen(view);
cb=[view.name ' = resetDisplayModes(', view.name, '); ', ...
	view.name ' = setPhWindow(' view.name ', [0 2*pi]); ', ...
	view.name ' = refreshScreen(', view.name, ');'];
uimenu(cmmenu, 'Label', 'Reset Defaults', 'Separator', 'off', ...
    'CallBack', cb);
 
rotateSubmenu(view,  cmmenu);
coModeSubmenu(view,  cmmenu);
ampModeSubmenu(view,  cmmenu);
phModeSubmenu(view,  cmmenu);
mapModeSubmenu(view,  cmmenu);

phprojMenu = uimenu(cmmenu, 'Label', 'Phase Projected...', 'Separator', 'on');
     coModeSubmenu(view,  phprojMenu,  'cor');
    ampModeSubmenu(view,  phprojMenu,  'projamp');
utilitySubmenu(view,  cmmenu);
visualFieldSubmenu(view,  cmmenu);


if isequal(view.viewType, 'Flat')
    uimenu(cmmenu, 'Label',  'Threshold Curvature', 'Separator', 'off', ...
	'CallBack', sprintf('%s = thresholdAnatMap(%s); ', view.name, view.name));
end


return;
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function view = rotateSubmenu(view,  cmmenu);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rotate cmap submenu
rotateMenu = uimenu(cmmenu, 'Label', 'Rotate/Flip', 'Separator', 'off');
 
cb=[view.name, '=flipCmap(', view.name, '); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Flip', 'Separator', 'off', ...
    'CallBack', cb);



cb=[view.name, '=rotateCmap(', view.name, '); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Rotate/Flip Using GUI', 'Separator', 'off', ...
    'CallBack', cb);

% Rotate callback:
%  view=rotateCmap(view, [amount]);
%  view=refreshScreen(view, 1);
cb=[view.name, '=rotateCmap(', view.name, ',  -45); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Left 45 degrees', 'Separator', 'off', ...
    'CallBack', cb);

cb=[view.name, '=rotateCmap(', view.name, ',  -90); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Left 90 degrees', 'Separator', 'off', ...
    'CallBack', cb);

cb=[view.name, '=rotateCmap(', view.name, ',  90); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(rotateMenu, 'Label', 'Right 90 degrees', 'Separator', 'off', ...
    'CallBack', cb);

cb=[view.name, '=rotateCmap(', view.name, ',  180); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(rotateMenu, 'Label', '180 degrees', 'Separator', 'off', ...
    'CallBack', cb);

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function view = coModeSubmenu(view,  cmmenu,  tag);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Coherence/Correlation Mode submenu: exactly same menu

% tag: coherence 'co' or correlation 'cor'
if ~exist('tag', 'var'); tag = 'co'; end;
    
if strcmpi(tag, 'co');
    comenu = uimenu(cmmenu, 'Label', 'Coherence Mode', 'Separator', 'off');
else
    comenu = uimenu(cmmenu, 'Label', 'Correlation Mode', 'Separator', 'off');
end

% redGreen callback:
%  view.ui.coMode=setColormap(view.ui.coMode, 'redGreenCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''redGreenCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(comenu, 'Label', 'Red-Green Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% hot callback:
%  view.ui.coMode=setColormap(view.ui.coMode, 'hotCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''hotCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(comenu, 'Label', 'Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool callback:
%  view.ui.coMode=setColormap(view.ui.coMode, 'coolCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''coolCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(comenu, 'Label', 'Cool Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool_hot callback:
%  view.ui.coMode=setColormap(view.ui.coMode, 'cool_hotCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''cool_hotCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(comenu, 'Label', 'Cool <-> Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool_spring callback:
%  view.ui.coMode=setColormap(view.ui.coMode, 'cool_springCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''cool_springCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(comenu, 'Label', 'Cool <-> Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% jet callback:
%  view.ui.coMode=setColormap(view.ui.coMode, 'jetCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', view.name, '.ui.', tag, 'Mode, ''jetCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(comenu, 'Label', 'Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', view.name, '.ui.', tag, 'Mode, ''revjetCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(comenu, 'Label', 'Reversed Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);

cb=[view.name, '.ui.', tag, 'Mode=setColormap(', view.name, '.ui.', tag, 'Mode, ''redBlueCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(comenu, 'Label', 'Blue <-> Red Colormap', 'Separator', 'off', ...
    'CallBack', cb);

%edit colormap callback:
% view.ui.coMode.cmap = editCmap(view.ui.coMode);
% view.ui.coMode.name=inputdlg('Please Name Color Map','Color map',1,{'custom'});
% view=refreshScreen(view,1);
cb = [view.name,'.ui.',tag,'Mode.cmap=editCmap('...
    view.name,'.ui.',tag,'Mode);',...
    view.name,'.ui.',tag,'Mode.name=inputdlg(''Please Name Color'...
    'Map'',''Color Map'',1,{''custom''});'...
    view.name,'=refreshScreen(',view.name,',1);'];
uimenu(comenu,'Label','Edit Colormap','Separator','on',...
    'CallBack',cb);

% auto clip mode callback:
%  view = setClipMode(view, 'co', 'auto');
%  view=refreshScreen(view, 1);
cbstr = sprintf(['%s = setClipMode(%s, ''', tag, ''', ''auto'');'], view.name, view.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, view.name, view.name);
uimenu(comenu, 'Label', 'Auto Clip Mode', 'Separator', 'on', ...
    'CallBack', cbstr);

% manual clip mode callback:
%  view = setClipMode(view, 'co');
%  view=refreshScreen(view, 1);
cbstr = sprintf(['%s = setClipMode(%s, ''', tag, ''');'], view.name, view.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, view.name, view.name);
uimenu(comenu, 'Label', 'Manual Clip Mode', 'Separator', 'off', ...
    'CallBack', cbstr);


return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function view = ampModeSubmenu(view,  cmmenu,  tag);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Amplitude / Projected Amplitude Mode submenu: exactly same menu

% tag: amplitude 'amp' or projected amplitude 'projamp'
if ~exist('tag', 'var'); tag = 'amp'; end;

if strcmpi(tag, 'amp');
    ampmenu = uimenu(cmmenu, 'Label', 'Amplitude Mode', 'Separator', 'off');
else
    ampmenu = uimenu(cmmenu, 'Label', 'Projected Amp Mode', 'Separator', 'off');
end

% redGreen callback:
%  view.ui.ampMode=setColormap(view.ui.ampMode, 'redGreenCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''redGreenCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Red-Green Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% hot callback:
%  view.ui.ampMode=setColormap(view.ui.ampMode, 'hotCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''hotCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool callback:
%  view.ui.ampMode=setColormap(view.ui.ampMode, 'coolCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''coolCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Cool Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool_hot callback:
%  view.ui.ampMode=setColormap(view.ui.ampMode, 'cool_hotCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''cool_hotCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Cool <-> Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% HSV callback:
%  view.ui.mapMode = setColormap(view.ui.mapMode,  'hsvCmap');
%  view = refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''hsvTbCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(ampmenu,  'Label',  'HSV (Rainbow - untill blue only) Colormap',  'Separator',  'off',  ...
       'Callback',  cb);

% jet callback:
%  view.ui.ampMode=setColormap(view.ui.ampMode, 'jetCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.', tag, 'Mode=setColormap(', ...
	view.name, '.ui.', tag, 'Mode, ''jetCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(ampmenu, 'Label', 'Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% HSV callback:
%  view.ui.ampMode=setColormap(view.ui.ampMode,'hsvCmap');
%  view=refreshScreen(view,1);
cb=[view.name,'.ui.',tag,'Mode=setColormap(',...
	view.name,'.ui.',tag,'Mode,''hsvCmap''); ',...
	view.name,'=refreshScreen(',view.name,',1);'];
uimenu(ampmenu,'Label','HSV Colormap','Separator','off',...
    'CallBack',cb);

%edit colormap callback:
% view.ui.ampMode.cmap = editCmap(view.ui.ampMode);
% view.ui.ampMode.name=inputdlg('Please Name Color Map','Color map',1,{'custom'});
% view=refreshScreen(view,1);
cb = [view.name,'.ui.',tag,'Mode.cmap=editCmap('...
    view.name,'.ui.',tag,'Mode);',...
    view.name,'.ui.',tag,'Mode.name=inputdlg(''Please Name Color'...
    'Map'',''Color Map'',1,{''custom''});'...
    view.name,'=refreshScreen(',view.name,',1);'];
uimenu(ampmenu,'Label','Edit Colormap','Separator','on',...
    'CallBack',cb);

% auto clip mode callback:
%  view = setClipMode(view, 'co', 'auto');
%  view=refreshScreen(view, 1);
cbstr = sprintf(['%s = setClipMode(%s, ''', tag, ''', ''auto'');'], view.name, view.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, view.name, view.name);
uimenu(ampmenu, 'Label', 'Auto Clip Mode', 'Separator', 'on', ...
    'CallBack', cbstr);

% manual clip mode callback:
%  view = setClipMode(view, 'co');
%  view=refreshScreen(view, 1);
cbstr = sprintf(['%s = setClipMode(%s, ''', tag, ''');'], view.name, view.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, view.name, view.name);
uimenu(ampmenu, 'Label', 'Manual Clip Mode', 'Separator', 'off', ...
    'CallBack', cbstr);


return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function view = phModeSubmenu(view,  cmmenu);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Phase Mode submenu

phmenu = uimenu(cmmenu, 'Label', 'Phase Mode', 'Separator', 'off');

cb = [view.name, ...
        '=cmapImportModeInformation(', view.name, ', ''phMode''', ', ''WedgeMapLeft.mat'');'...
        view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Wedge map (left)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [view.name, '=cmapImportModeInformation(', view.name, ', ''phMode''', ', ''WedgeMapRight.mat'');'...
        view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Wedge map (right)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [view.name, ...
        '=cmapImportModeInformation(', view.name, ', ''phMode''', ', ''WedgeMapLeft_pRF.mat'');'...
        view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Wedge map for pRF (left)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [view.name, '=cmapImportModeInformation(', view.name, ', ''phMode''', ', ''WedgeMapRight_pRF.mat'');'...
        view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Wedge map for pRF (right)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [view.name, '=cmapImportModeInformation(', view.name, ', ''phMode''', ', ''RingMapE.mat'');'...
        view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Ring map (expanding)', 'Separator', 'off', ...
    'CallBack', cb);

cb = [view.name, '=cmapImportModeInformation(', view.name, ', ''phMode''', ', ''RingMapC.mat'');'...
        view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Ring map (contracting)', 'Separator', 'off', ...
    'CallBack', cb);

% HSV callback:
%  view.ui.phMode=setColormap(view.ui.phMode, 'hsvCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.phMode=setColormap(', ...
	view.name, '.ui.phMode, ''hsvCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'HSV Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% Extended color map callback:
% VOLUME{2}=cmapExtended(VOLUME{2});%
% VOLUME{2}=refreshScreen(VOLUME{2}, 1);
%
cb= ...
    [view.name, '=cmapExtended(', view.name, '); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Extended Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% RYGB callback:
%  view.ui.phMode=setColormap(view.ui.phMode, 'rygbCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.phMode=setColormap(', ...
	view.name, '.ui.phMode, ''rygbCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'RYGB Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% RedGreenBlue cmap (ras, 10/06)
cb = [sprintf('%s = cmapRedgreenblue(%s, ''ph'', 2); ', view.name, view.name) ...
	  sprintf('%s = refreshScreen(%s); ', view.name, view.name)];
uimenu(phmenu, 'Label', 'Redgreenblue Colormap (full range)', ...
               'Separator', 'off', 'CallBack', cb);

cb = [sprintf('%s = cmapRedgreenblue(%s, ''ph'', 0); ', view.name, view.name) ...
	  sprintf('%s = refreshScreen(%s); ', view.name, view.name)];
uimenu(phmenu, 'Label', 'Redgreenblue Colormap (half range)', ...
               'Separator', 'off', 'CallBack', cb);

cb = [sprintf('%s = cmapRedgreenblue(%s, ''ph'', 1); ', view.name, view.name) ...
	  sprintf('%s = refreshScreen(%s); ', view.name, view.name)];
uimenu(phmenu, 'Label', 'Redgreenblue Colormap (4 color bands)', ...
               'Separator', 'off', 'CallBack', cb);
           
% blueyellow cmap		   
cb = [view.name, '.ui.phMode=setColormap(', ...
	  view.name, '.ui.phMode, ''blueyellowCmap''); ', ...
	  view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Blue->Yellow Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% blueredyellow cmap		   
cb = [view.name, '.ui.phMode=setColormap(', ...
	  view.name, '.ui.phMode, ''blueredyellowCmap''); ', ...
	  view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Blue->Red->Yellow Colormap', 'Separator', 'off', ...
    'CallBack', cb);


% Jet callback:
%  view.ui.phMode=setColormap(view.ui.phMode, 'jetCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.phMode=setColormap(', ...
	view.name, '.ui.phMode, ''jetCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% Jet callback:
%  view.ui.phMode=setColormap(view.ui.phMode, 'hotCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.phMode=setColormap(', ...
	view.name, '.ui.phMode, ''hotCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);


% Linearize callback:
%  view=linearizeCmap(view);
%  view=refreshScreen(view, 1);
cb= [view.name, '=linearizeCmap(', view.name, '); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(phmenu, 'Label', 'Linearize HSV', 'Separator', 'off', ...
    'CallBack', cb);

%edit colormap callback:
% view.ui.phMode.cmap = editCmap(view.ui.phMode);
% view.ui.phMode.name=inputdlg('Please Name Color Map','Color map',1,{'custom'});
% view=refreshScreen(view,1);
cb = [view.name,'.ui.phMode.cmap=editCmap('...
    view.name,'.ui.phMode);',...
    view.name,'.ui.phMode.name=inputdlg(''Please Name Color'...
    'Map'',''Color Map'',1,{''custom''});'...
    view.name,'=refreshScreen(',view.name,',1);'];
uimenu(phmenu,'Label','Edit Colormap','Separator','on',...
    'CallBack',cb);

% auto clip mode callback:
%  view = setClipMode(view, 'co', 'auto');
%  view=refreshScreen(view, 1);
cbstr = sprintf('%s = setClipMode(%s, ''ph'', ''auto'');', view.name, view.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, view.name, view.name);
uimenu(phmenu, 'Label', 'Auto Clip Mode', 'Separator', 'on', ...
    'CallBack', cbstr);

% manual clip mode callback:
%  view = setClipMode(view, 'co');
%  view=refreshScreen(view, 1);
cbstr = sprintf('%s = setClipMode(%s, ''ph'');', view.name, view.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, view.name, view.name);
uimenu(phmenu, 'Label', 'Manual Clip Mode', 'Separator', 'off', ...
    'CallBack', cbstr);


return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function view = mapModeSubmenu(view,  cmmenu);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameter map Mode submenu
mapmenu = uimenu(cmmenu, 'Label', 'Parameter Map Mode', 'Separator', 'off');

%% ras 06/07: putting two options at the top of this submenu:
% (1) New dialog to edit map name / units / clip mode
% (2) Remus' Cmap edit submenu

% edit map name/units menu:
cb = sprintf('%s = viewSet(%s, ''MapName'', ''Dialog''); ', ...
			 view.name, view.name);
uimenu(mapmenu, 'Label', 'Edit Map Name / Units', 'Separator','off',...
		'CallBack', cb);

% edit colormap callback:
%  view.ui.mapMode.cmap = editCmap(view.ui.mapMode);
%  view.ui.mapMode.name=inputdlg('Please Name Color Map','Color map',1,{'custom'});
%  view=refreshScreen(view,1);
cb = [view.name,'.ui.mapMode.cmap=editCmap('...
    view.name,'.ui.mapMode);',...
    view.name,'.ui.mapMode.name=inputdlg(''Please Name Color'...
    'Map'',''Color Map'',1,{''custom''});'...
    view.name,'=refreshScreen(',view.name,',1);'];
uimenu(mapmenu, 'Label', 'Edit Colormap', 'Separator', 'off',...
		'CallBack', cb);


% gray callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'redGreenCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''grayColorCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Gray (anat-like) Colormap', 'Separator', 'on', ...
    'CallBack', cb);

% redGreen callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'redGreenCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''redGreenCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Red-Green Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% hot callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'hotCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''hotCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Hot Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'coolCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''coolCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Cool Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% cool_spring callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'cool_springCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''cool_springCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Cool_spring Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% HSV callback:
%  view.ui.mapMode = setColormap(view.ui.mapMode,  'hsvCmap');
%  view = refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''hsvCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu,  'Label',  'HSV (Rainbow) Colormap',  'Separator',  'off',  ...
       'Callback',  cb);

% Linearize callback:
%  view=linearizeCmap(view);
%  view=refreshScreen(view, 1);
cb= [view.name, '=linearizeCmap(', view.name, '); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Linearize HSV', 'Separator', 'off', ...
    'CallBack', cb);


% HSV callback:
%  view.ui.mapMode = setColormap(view.ui.mapMode,  'hsvCmap');
%  view = refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''hsvTbCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu,  'Label',  'HSV (Rainbow - untill blue only) Colormap',  'Separator',  'off',  ...
       'Callback',  cb);


% jet callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'jetCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''jetCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu,  'Label',  'Jet Colormap',  'Separator',  'off', ...
        'CallBack',  cb);

% reversed jet:
cb=[view.name, '.ui.mapMode=setColormap(', view.name, '.ui.mapMode, ''revjetCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Reversed Jet Colormap', 'Separator', 'off', ...
    'CallBack', cb);    
    
% blueyellow callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'jetCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''blueyellowCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu,  'Label',  'Blueyellow Colormap',  'Separator',  'off', ...
        'CallBack',  cb);

% blueredyellow callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'jetCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''blueredyellowCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu,  'Label',  'Blueredyellow Colormap',  'Separator',  'off', ...
        'CallBack',  cb);

% bluegreenyellow callback:
%  view.ui.mapMode=setColormap(view.ui.mapMode, 'jetCmap');
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''bluegreenyellowCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu,  'Label',  'Bluegreenyellow Colormap',  'Separator',  'off', ...
        'CallBack',  cb);

% Autumn callback:
%  view = bicolorCmap(view);
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''autumnCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Autumn Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% Winter callback:
%  view = bicolorCmap(view);
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''winterCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Winter Colormap', 'Separator', 'off', ...
    'CallBack', cb);

% Bicolor callback:
%  view = bicolorCmap(view);
%  view=refreshScreen(view, 1);
cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''coolhotCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Bicolor (cool + hot, black centered) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

cb=[view.name, '.ui.mapMode=setColormap(', ...
	view.name, '.ui.mapMode, ''coolhotGrayCmap''); ', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(mapmenu, 'Label', 'Bicolor (cool + hot, gray centered) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

cb = sprintf('%s = bicolorCmap(%s); ', view.name, view.name);
cb = [cb sprintf('%s = refreshScreen(%s, 1);', view.name, view.name)];
uimenu(mapmenu, 'Label', 'Bicolor (Winter+Autumn) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

% Overlap Cmap menu options:
cb = sprintf('cmapOverlap(%s,  {''r'' ''g'' ''y''}); ',  view.name);
uimenu(mapmenu, 'Label', 'Overlap (Red/Green/Yellow) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

cb = sprintf('cmapOverlap(%s,  {''r'' ''b'' ''m''}); ',  view.name);
uimenu(mapmenu, 'Label', 'Overlap (Red/Blue/Purple) Colormap', ...
    'Separator', 'off', 'CallBack', cb);

% auto clip mode callback:
%  view = setClipMode(view, 'co', 'auto');
%  view=refreshScreen(view, 1);
cbstr = sprintf('%s = setClipMode(%s, ''map'', ''auto'');', view.name, view.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, view.name, view.name);
uimenu(mapmenu, 'Label', 'Auto Clip Mode', 'Separator', 'on', ...
    'CallBack', cbstr);

% manual clip mode callback:
%  view = setClipMode(view, 'co');
%  view=refreshScreen(view, 1);
cbstr = sprintf('%s = setClipMode(%s, ''map'');', view.name, view.name);
cbstr = sprintf('%s\n%s = refreshScreen(%s, 1);', cbstr, view.name, view.name);
uimenu(mapmenu, 'Label', 'Manual Clip Mode', 'Separator', 'off', ...
    'CallBack', cbstr);


return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function view = visualFieldSubmenu(view,  cmmenu);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Assign Visual Field Map Parameters submenu:
retinoMapMenu = uimenu(cmmenu,  'Label',  'Set Retinotopy Parameters...',  ...
                        'Separator',  'off');

% submenus for assigning visual field map params
% retinoSetParams(view);
cb = sprintf('retinoSetParams(%s); ',  view.name);
uimenu(retinoMapMenu,  'Label',  'Current Scan',  'Callback',  cb);

% scans = er_selectScans(view); retinoSetParams(view,  [],  scans); 
cb = [sprintf('scans = er_selectScans(%s); ',  view.name) ...
      sprintf('retinoSetParams(%s,  [],  scans); ',  view.name)];
uimenu(retinoMapMenu,  'Label',  'Select Scans',  'Callback',  cb);

% retinoSetParams(view,  [],  1:numScans(view));
cb = sprintf('retinoSetParams(%s,  [],  1:numScans(%s)); ',  ...
               view.name,  view.name);
uimenu(retinoMapMenu,  'Label',  'All Scans',  'Callback',  cb);

% submenus for removing visual field map params
% retinoSetParams(view,  [],  [],  'none');
cb = sprintf('retinoSetParams(%s,  [],  [],  ''none''); ',  view.name);
uimenu(retinoMapMenu,  'Label',  'Un-set Params (Current Scan)',  ...
       'Separator',  'on',  'Callback',  cb);

% scans = er_selectScans(view); retinoSetParams(view,  [],  scans,  'none'); 
cb = [sprintf('scans = er_selectScans(%s); ',  view.name) ...
      sprintf('retinoSetParams(%s,  [],  scans,  ''none''); ',  view.name)];
uimenu(retinoMapMenu,  'Label',  'Un-set Params (Select Scans)',  ...
    'Callback',  cb);

% retinoSetParams(view,  [],  1:numScans(view),  'none');
cb = sprintf('retinoSetParams(%s,  [],  1:numScans(%s),  ''none''); ',  ...
               view.name,  view.name);
uimenu(retinoMapMenu,  'Label',  'Un-set Params (All Scans)',  ...
    'Callback',  cb);

%% some pre-set cmaps which may be useful (but which explicitly 
%% depend on having set retinoParams):

% polar angle, RGB, left visual field
cb = [sprintf('%s = cmapPolarAngleRGB(%s, ''left''); \n', view.name, view.name) ...
      sprintf('%s = refreshScreen(%s); ', view.name, view.name)];
uimenu(retinoMapMenu,  'Label',  'Left Visual Field Colorwheel',  ...
    'Separator', 'on', 'Callback', cb);

% polar angle, RGB, left visual field
cb = [sprintf('%s = cmapPolarAngleRGB(%s, ''right''); \n', view.name, view.name) ...
      sprintf('%s = refreshScreen(%s); ', view.name, view.name)];
uimenu(retinoMapMenu,  'Label',  'Right Visual Field Colorwheel',  ...
    'Callback', cb);


return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function view = utilitySubmenu(view,  cmmenu);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% utility mode

utilitymenu = uimenu(cmmenu, 'Label', 'Utilities', 'Separator', 'on');

% copy colorbar to clipboard
cb = sprintf('cbarCopy(%s, ''clipboard'');',  view.name);
uimenu(utilitymenu,  'Label',  'Copy Color bar to Clipboard',  ...
        'Separator',  'off',  'Callback',  cb);

% copy colorbar to figure
cb = sprintf('cbarCopy(%s, ''figure'');',  view.name);
uimenu(utilitymenu,  'Label',  'Copy Color bar to Figure',  ...
        'Separator',  'off',  'Callback',  cb);

cb = sprintf('loadColormap(%s);',  view.name);
uimenu(utilitymenu,  'Label',  'Load Colormap From File',  ...
        'Separator',  'on',  'Callback',  cb);

cb = [view.name, '=cmapImportModeInformation(', view.name, ');'];
uimenu(utilitymenu, 'Label', 'Import Map', 'Separator', 'off', ...
        'CallBack',  cb);

cb = ['cmapExportModeInformation(', view.name, ');'];
uimenu(utilitymenu,  'Label',  'Export Map',  'Separator',  'off', ...
        'CallBack',  cb);

% Rotate the color map so that a particular data phase has the chosen color:
%  view = =cmapSetDataPhase(view);
%  view = refreshScreen(view, 1);
cb=[view.name, '=cmapSetDataPhase(', view.name, ');', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(utilitymenu, 'Label', 'Set Phase Manually...', 'Separator', 'off', ...
    'CallBack', cb);

% Rotate the color map so that a particular data phase has the chosen color:
%  view = cmapSetConstantSubmap(view);
%  view = refreshScreen(view, 1);
cb=[view.name, '=cmapSetConstantSubmap(', view.name, ');', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(utilitymenu, 'Label', 'Set Map Region Gray...', 'Separator', 'off', ...
    'CallBack', cb);
cb=[view.name, '=cmapSetConstantSubmap(', view.name, ', [], ''a'');', ...
	view.name, '=refreshScreen(', view.name, ', 1);'];
uimenu(utilitymenu, 'Label', 'Set Map Region Gray by Input', 'Separator', 'off', ...
    'CallBack', cb);

% cmapRing(FLAT{1}, fovealPhase, 'b', 256, 1);
cb= ['cmapRing(', view.name, ', [], ''b'', 256, 1);'];
uimenu(utilitymenu, 'Label', 'Ring map legend', 'Separator', 'off', ...
    'CallBack', cb);

cb= ['cmapWedge(', view.name, ');'];
uimenu(utilitymenu, 'Label', 'Wedge map legend', 'Separator', 'off', ...
    'CallBack', cb);



return
% /--------------------------------------------------------------------/ %
