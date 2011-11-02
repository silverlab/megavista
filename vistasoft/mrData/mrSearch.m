function varargout = mrSearch(varargin)
% MRSEARCH Application M-file for mrSearch.fig
%    FIG = MRSEARCH launch query GUI.
%    MRSEARCH('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.0 23-Jan-2001 18:36:08

if nargin == 0  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
    
    handles.fig = fig;
    handles.tableList = {};
    handles.found = {};
    handles.colNames = {};
    
    % Build table list
    handles.searchString = '';
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
    if(length(tables)<1)
        addStatusTxt(fig, handles, ['No tables found- maybe a problem connecting to database?']);
    elseif(length(tables)==1)
        addStatusTxt(fig, handles, ['Found 1 table.']);
    else
        addStatusTxt(fig, handles, ['Found ',num2str(length(tables)),' tables.']);
    end 
    
    set(handles.edit1,'String',handles.searchString);
    set(handles.listbox1,'String',handles.tableList);
    set(handles.listbox1,'Min',1);
    set(handles.listbox1,'Max',10);
    
    set(handles.listbox2,'String',{'none'});
    set(handles.listbox2,'Min',1);
    set(handles.listbox2,'Max',100);
    
	guidata(fig, handles);

	if nargout > 0
		varargout{1} = fig;
	end

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
% Stub for Callback of the uicontrol handles.edit1.
handles.searchString = get(handles.edit1,'String');


% --------------------------------------------------------------------
function varargout = pushbutton1_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.pushbutton1.
handles.searchString = get(handles.edit1,'String');
listVals = get(handles.listbox1, 'Value');
tables = handles.tableList(listVals);
addStatusTxt(h, handles, ['Searching ',implode(', ',tables),'...']);
[handles.found,handles.colNames] = mrdSearch(handles.searchString, tables);
set(handles.listbox2,'Value',1);
listStr = {};
ud.tableNum = {};
ud.tableIndex = {};
ud.numTables = size(handles.found, 1);
%if(ud.numTables==1) handles.found{1} = handles.found; end
for(i=[1:ud.numTables])
    listRowNum = 0;
    for(j=[1:size(handles.found{i}, 1)])
        listRowNum = length(listStr)+1;
        ud.tableNum{listRowNum} = listVals(i);
        ud.tableIndex{listRowNum} = i;
        ud.rowNum{listRowNum} = j;
        listStr{listRowNum} = sprintf('%-15s %-5d', tables{i}, handles.found{i}{j,1});
        % TO DO: more intellegent handling of different data types.
        for(k=[2:min(size(handles.found{i},2),4)])
            if(isnumeric(handles.found{i}{j,k}))
                fmt = '%-s %-30d ';
            else
                fmt = '%-s %-30s ';
            end
            listStr{listRowNum} = sprintf(fmt, listStr{listRowNum}, handles.found{i}{j,k});
        end
    end
    if(listRowNum==1)
        addStatusTxt(h, handles, ['Found 1 row of data in ',tables{i},'.']);
    else
        addStatusTxt(h, handles, ['Found ',num2str(listRowNum),' rows of data in ',tables{i},'.']);
    end
end
set(handles.listbox2,'String',listStr);
set(handles.listbox2,'UserData',ud);
guidata(h, handles);


% --------------------------------------------------------------------
function varargout = listbox1_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.listbox1.



% --------------------------------------------------------------------
function varargout = listbox2_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.listbox2.
listVal = get(handles.listbox2, 'Value');
ud = get(handles.listbox2, 'Userdata');
% tableIndex here is the table number in the "found" list.
% tableNum is the actual table number in the master table list.
values = handles.colNames{ud.tableIndex{listVal}};
for(i=[1:length(values)])
    data = handles.found{ud.tableIndex{listVal}}{ud.rowNum{listVal},i};
    if(isnumeric(data))
        values{i} = [values{i},': ',num2str(data)];
    else
        values{i} = [values{i},': ',data];
    end
end
uiwait(msgbox(values, [handles.tableList{ud.tableNum{listVal}},'  ',num2str(values{1})], 'modal'));



% --------------------------------------------------------------------
function varargout = edit3_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.edit3.


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