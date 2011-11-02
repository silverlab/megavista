function varargout = mrdUIGetFile(varargin)
% mrdUIGetFile Application M-file for mrdUIGetFile.fig
%    files = mrdUIGetFile([fileTypeExtension]) launch mrData file browser GUI.
%    mrdUIGetFile('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.0 03-Apr-2001 17:50:28

if nargin <= 1  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
    
    % make it modal
    set(fig,'WindowStyle','modal');

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
    
    handles.fig = fig;
    handles.tableList = {};
    handles.found = {};
    handles.colNames = {};
    if nargin == 1
        handles.fileType = varargin(1);
    else
        handles.fileType = '*.*';
    end
    
    set(handles.listbox1,'String',{'none'});
    set(handles.listbox1,'Min',1);
    set(handles.listbox1,'Max',100);
    
    handles.file = 0;
    
    % Build table list
    % (We don't really need to do this.)
    set(handles.statusText,'String',char(' ',' ',' ',' ',' '));
    addStatusTxt(fig, handles, 'Connecting to database to fetch table list...');
    tables = mrdGetTables;
    for i=[1:length(tables)]
        % we don't want to include our cross-link tables.  
        % (By convention, cross-link table names all begin with 'x'.)
        if(tables{i}(1)~='x')
            handles.tableList{length(handles.tableList)+1} = tables{i};
        end
    end
    if(length(tables)==1)
        addStatusTxt(fig, handles, ['Found 1 table.']);
    else
        addStatusTxt(fig, handles, ['Found ',num2str(length(tables)),' tables.']);
    end 
    
    % POPULATE POP-UPS
    % MySQL puts the enum options list in the 'size' attribute of
    % a column's metadata, so we get that list from the 'size' field.
    [colNames, colInfo] = mrdGetColumns('scans');
    set(handles.popup_scantype, 'String', cat(2,{'ALL TYPES'},colInfo{11}.size));
    
    [colNames, colInfo] = mrdGetColumns('dataFiles');
    set(handles.popup_datatype, 'String', cat(2,{'ALL TYPES'},colInfo{7}.size));
    
	guidata(fig, handles);
    
    uiwait(fig);
    
    handles = guidata(fig);
    if(~iscell(handles.file))
        handles.file = {handles.file};
    end
    for(i=[1:length(handles.file)])
        if(~ischar(handles.file{i}))
            if(handles.file{i}>0)
                handles.file{i} = mrdGetFileFromDB(handles.file{i});
            end
        end
    end
    
	%if nargout > 0
    varargout{1} = handles.file;
    %end
    close(fig);
    %delete(fig);
    
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
	catch
		disp(lasterr);
	end

end


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.



% --------------------------------------------------------------------
function varargout = edit1_Callback(h, eventdata, handles, varargin)
% subject or study contact name: handles.edit1
%guidata(h, handles);

% --------------------------------------------------------------------
function varargout = edit2_Callback(h, eventdata, handles, varargin)
% study notes: handles.edit2

% --------------------------------------------------------------------
function varargout = edit3_Callback(h, eventdata, handles, varargin)
% stimulus type: handles.edit3

% --------------------------------------------------------------------
function varargout = edit4_Callback(h, eventdata, handles, varargin)
% scan type: handles.edit4


% --------------------------------------------------------------------
function varargout = edit5_Callback(h, eventdata, handles, varargin)
% Selected file ID: handles.edit5
tmp = str2num(get(handles.edit5,'String'));
if(tmp>0)
    handles.file = tmp;
    set(handles.pushbutton4,'Enable','on');
else
    handles.file = 0;
    set(handles.pushbutton4,'Enable','off');
end
guidata(h, handles);

% --------------------------------------------------------------------
function varargout = pushbutton1_Callback(h, eventdata, handles, varargin)
% SEARCH button: handles.pushbutton1
people = get(handles.edit1,'String');
studyNotes = get(handles.edit2,'String');
stimulus = get(handles.edit3,'String');
scan = get(handles.popup_scantype,'String');
scan = scan{get(handles.popup_scantype,'Value')};
datatype = get(handles.popup_datatype,'String');
datatype = datatype{get(handles.popup_datatype,'Value')};
listVals = get(handles.listbox1, 'Value');
%tables = handles.tableList(listVals);
%addStatusTxt(h, handles, ['Searching ',implode(', ',tables),'...']);
query = ['select DISTINCT dataFiles.id,dataFiles.createdOn,dataFiles.dataType,',...
        'dataFiles.fileSize,dataFiles.path ',...
        'FROM dataFiles,people,scans,studies ',...
        'WHERE (people.lastName LIKE "%',people,'%" ',...
        'OR people.firstName LIKE "%',people,'%") ',...
        'AND (scans.subjectID=people.id OR studies.contactID=people.id) ',...
        'AND dataFiles.scanID=scans.id ',...
        'AND scans.stimulusType LIKE "%',stimulus,'%"'];
if(get(handles.popup_scantype,'Value') ~= 1)
    % the first field is 'any', so we shouldn't add this criteria if that is selected.
    query = [query,' AND scans.scanType="',scan,'" '];
end
if(get(handles.popup_datatype,'Value') ~= 1)
    % the first field is 'any', so we shouldn't add this criteria if that is selected.
    query = [query,' AND dataFiles.dataType="',datatype,'" '];
end
if(~isempty(studyNotes) & studyNotes~='')
    query = [query,' AND (studies.purpose LIKE "%',studyNotes,'%" ',...
            'OR studies.notes LIKE "%',studyNotes,'%") ',...
            'AND scans.primaryStudyID=studies.id'];
end
[handles.found,handles.colNames] = mrdQuery(query);

listStr = {};
listRowNum = 0;
ud.rowNum = {};
ud.fileID = {};
for(i=[1:size(handles.found, 2)])
    listRowNum = length(listStr)+1;
    listStr{listRowNum} = '';
    ud.rowNum{listRowNum} = i;
    ud.fileID{listRowNum} = str2num(handles.found{i}{1});
    for(j=[1:min(length(handles.found{i}),5)])
        listStr{listRowNum} = sprintf('%-s %-5s ', listStr{listRowNum}, handles.found{i}{j});
    end
end
if(listRowNum==1)
    addStatusTxt(h, handles, ['Found 1 row of data.']);
else
    addStatusTxt(h, handles, ['Found ',num2str(listRowNum),' rows of data.']);
end
set(handles.listbox1,'String',listStr);
set(handles.listbox1,'UserData',ud);
set(handles.listbox1,'Value',1);
handles.file = 0;
set(handles.edit5,'String','');
set(handles.pushbutton4,'Enable','off');
guidata(h, handles);

% --------------------------------------------------------------------
function varargout = pushbutton2_Callback(h, eventdata, handles, varargin)
% 'Browse local' button: handles.pushbutton2
[file,path] = uigetfile(handles.fileType, 'Select a Local File');
if(file~=0)
    handles.file = [path,file];
    guidata(h, handles);
    uiresume(gcbf);
end

% --------------------------------------------------------------------
function varargout = pushbutton3_Callback(h, eventdata, handles, varargin)
% HELP button: handles.pushbutton3
helpdlg(['Think of this figure as a file browser for the mrData Database. ',...
        'Use it to find and select any datafile registered with mrData. ',...
        'First, enter some criteria and press "Search". Select an item from ',...
        'the resulting list and then press "OK".  A local copy of the selected ',...
        'file will be made on your machine. (To skip mrData and simply browse ',...
        'files on your machine, press "Browse Local Files".)'],'Quick Help')
%web(which('mrdHelp.html'));

% --------------------------------------------------------------------
function varargout = pushbutton4_Callback(h, eventdata, handles, varargin)
% OK: handles.pushbutton4
%msgbox(handles.file);
addStatusTxt(h, handles, ['Retrieving selected files- Please wait...']);
uiresume(gcbf);
return;

% --------------------------------------------------------------------
function varargout = pushbutton5_Callback(h, eventdata, handles, varargin)
% Cancel:  handles.pushbutton5
handles.file = 0;
guidata(h, handles);
uiresume(gcbf);
return;


% --------------------------------------------------------------------
function varargout = listbox1_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.listbox1.
listVal = get(handles.listbox1, 'Value');
ud = get(handles.listbox1, 'Userdata');
%values = handles.colNames;
%for(i=[1:length(values)])
%    values{i} = [upper(values{i}),':',handles.found{ud.rowNum{listVal}}{i}];
%end
set(handles.pushbutton4,'Enable','on');
handles.file = cell(1,length(listVal));
for(i=1:length(listVal))
    handles.file{i} = ud.fileID{listVal(i)};
end
set(handles.edit5,'String',implode(',',handles.file));
%uiwait(msgbox(values, [num2str(values{1})], 'modal'));
guidata(h, handles);


% --------------------------------------------------------------------
function varargout = popup_scantype_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.popup_scantype.

% --------------------------------------------------------------------
function varargout = popup_datatype_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.popup_datatype.


% --------------------------------------------------------------------
function varargout = close_Callback(h, eventdata, handles, varargin)
% Clean up and close the window
close(handles.fig);


function addStatusTxt(h, handles, statusTxt)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% function addStatusTxt ( statusTxt )
%
% DESCRIPTION
%   Displays scrolling status text in uicontrol text box.
% 
% INPUT
%   status text string
%
% OUTPUT
%   none
%
% AUTHOR:
%   Volker Maximillian Koch
%   vk@volker-koch.de
%
% DATE:
%   Feb 2001
%
% COMMENTS:
%   uicontrol text box initialization: 
%        ud.ui.ExplanatoryText = uicontrol( Text, ...
%           'Position',[left,bot,width,height], ...
%           'BackgroundColor', [0.9 0.9 0.9], ...
%           'ForegroundColor', [0 0 0], ...
%           'HorizontalAlignment', 'Left', ...
%           'String', char(' ',' ',' ',' ',' ',' ',' '));
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


numOfColumns = 85;

%findBordersFig = findobj(allchild(0), 'tag', 'Find Borders');
%ud = get(findBordersFig, 'Userdata');

% test length of status text
while size(statusTxt,2) > numOfColumns
    vShowStatusTxt(strcat(statusTxt(1:numOfColumns-3),'...'));
    statusTxt = strcat('...', statusTxt(numOfColumns-2:size(statusTxt,2)));
end

% get old text
oldStatusTxt = get(handles.statusText, 'String'); 

% determine number of rows currently displayed
oldNumRows = size(oldStatusTxt,1);

% get rid of first row(s) of old text and add new row
newStatusTxt = char(oldStatusTxt(2:oldNumRows,:),statusTxt);

% display text in find borders figure
set(handles.statusText, 'String', newStatusTxt); 

% display text in workspace window
%disp(statusTxt);

%set(findBordersFig,'Userdata',ud);


