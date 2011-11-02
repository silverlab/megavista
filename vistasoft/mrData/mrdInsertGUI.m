function fig = mrdInsertGUI(varargin)
% 
% fig = mrdInsertGUI(table, [values])
%
% MrData GUI function to insert data into the default database.  If the 
% record specified by the value list already exists, that row will 
% be updated.  Otherwise, a new row will be inserted.
%
% 'Values', and the corresponding 'fields', specify the optional default 
% values.
%
% We will open and close our own connection.
%
% RETURNS: the result- 0 for failure, 1 for a successful insert, and 
%   >= 1 for a successful update (ie. the number of updated rows.)
%
% 2001.01.25 Bob Dougherty <bob@white.stanford.edu>
% 2001.04.05 Bob D- fixed bug- go_callback sometimes tried to read a non-existant
%   field of the guidata 'popup' field.
%

if (nargin>3 & ischar(varargin{1})) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    try
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    catch
        disp(lasterr);
    end
else
    import java.sql.*;
    import java.io.*;
    
    fig = figure;
    
    % Use system color scheme for figure:
    set(fig,'WindowStyle','modal');
    set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
    set(fig,'Name',['MrData Insert: ',varargin{1}]);
    
    % Generate a structure of handles to pass to callbacks, and store it. 
    handles = guihandles(fig);
    
    if(nargin<3)
        handles.db = mrdConnect;
        handles.closeDB = 1;
    else
        handles.db = varargin{3};
        handles.closeDB = 0;
    end
    
    handles.table = varargin{1};
    handles.statement = handles.db.createStatement;
    
    [handles.columnNames, handles.columnInfo] = mrdGetColumns(handles.table, handles.db);
    numFields = length(handles.columnNames);
    handles.links = mrdGetLinks(handles.table, handles.db);
    % get cross-links, if any
    handles.XLinks = mrdGetLinks(handles.table, handles.db, 1);
    
    % The second arg in is an optional id number or a set of {fieldName,value,fixFlag} items.
    % If the id number is present, we will go into 'update' mode.  If the field names & values are
    % present, then we use those as defaults.
    handles.values = cell(1,numFields);
    handles.values{1} = 0;
    handles.valueFixed = zeros(1,numFields);
    % all values default to non-fixed, except:
    if(strcmp(handles.columnNames{1},'id'))
        handles.valueFixed(1) = 1;
    end
    handles.thisID = 0;
    if(nargin>=2)
        if(iscell(varargin{2}))
            for(i=[1:3:length(varargin{2})])
                m = strmatch(varargin{2}{i}, handles.columnNames);
                if(~isempty(m))
                    m = m(1);   % just in case there are more than 1 matches (there shouldn't be!)
                    handles.values{m} = varargin{2}{i+1};
                    handles.valueFixed(m) = varargin{2}{i+2};
                end
            end
        else
            handles.thisID = varargin{2};
        end
    end
    
    % If any of the fields are links to other tables, this array will specify 
    % whitch item in the handles.links cellarray goes with the field.  If the
    % field is not linked, it will be zero.
    handles.fieldLinks = zeros(numFields,1);
    handles.ed = zeros(numFields,1);
    handles.popup = zeros(numFields,1);
    
    % This will be a cell array of numeric arrays, one for each linked field.
    % It will contain the database index ('id', always the first column by convention)
    % for each item in the popup list.
    handles.linkedItemIDs = {};
    
    % we use a simple flag to indicate unsaved changes
    handles.dirty = 0;
    
    if(handles.thisID)
        found = mrdSearch(num2str(handles.thisID), handles.table, 'id');
        if(length(found{1})~=1)
            warndlg(['No unique record with id "',num2str(handles.thisID),...
                    '" found! Reverting to INSERT mode.'], 'mrData Warning');
            handles.thisID = 0;
        else
            handles.values = found{1}{1};
        end
    end
    
    footer = 40; % pixel-height of footer region (which contains the pushbuttons)
    fieldHt = 30; % pixel-height of each text entry field
    numRows = numFields+length(handles.XLinks);
    
    pos = get(fig,'Position');
    pos(3) = 500;
    pos(4) = fieldHt*numRows+footer;
    set(fig,'Position',pos);
    
    %'BackgroundColor',[1,1,1], ...
    for i=[1:numFields]
        handles.edt(i) = uicontrol(fig, ...
            'Style','text', ...
            'String',[handles.columnNames{i},':'], ...
            'HorizontalAlignment','Right', ...
            'Position',[10 fieldHt*(numRows-i)+footer+8 120 20]);
        
        % Loop through the links and see if the current column is linked to something
        % *** maybe replace the following with strmatch ***
        for j=[1:size(handles.links,2)]
            % handles.links{n}{1} is the 'from' table name
            % handles.links{n}{2} is the 'from' field name
            % handles.links{n}{3} is the 'to' table name
            % handles.links{n}{4} is the 'to' field name (should always be 'id')
            if(strcmp(handles.columnNames{i},handles.links{j}{2}))
                handles.fieldLinks(i) = j;
            end
        end
        if(handles.fieldLinks(i))
            % there is a link- put up a pop-up menu of choices from the linked table
            % For this list, we just grab the first 3 columns.  Hopefully, that's enough
            % for the user to decide which item they want.
            % Remember, handles.links{n}{2} is the 'to' table name.
            itemCell = mrdSelect(handles.links{handles.fieldLinks(i)}{3}, '', [1:3], handles.db);
            listItems = cell(size(itemCell,1)+1,1);
            value = 1;
            
            handles.linkedItemIDs{i} = {};
            listItems{1} = ['Select from "',handles.links{handles.fieldLinks(i)}{3},'"'];
            listItems{2} = 'Create new record';
            
            % The first two items in the pull-down list are 'select an item' and
            % 'create new item', so they don't get real database indices.
            % For the rest, we have to be sure to grab the 'id' (which is always the
            % first field- itemCell{x}{1} in this case- and build a proper linkedItemIDs
            % hash table.  We need this so that we can translate the popup's 'Value' field
            % into a database item ID number.
            handles.linkedItemIDs{i}{1} = '0';
            handles.linkedItemIDs{i}{2} = '0';
            for j=[1:size(itemCell,2)]
                handles.linkedItemIDs{i}{j+2} = itemCell{j}{1};
                listItems{j+2} = implode(' ',itemCell{j});
                % let's remember the popup index of the current item id, if there is one.
                % (this is used for the setting the default popup value below.)
                if(ischar(handles.values{i}) & str2num(itemCell{j}{1}) == str2num(handles.values{i}))
                    value = j+2;
                end
            end
            if(handles.valueFixed(i))
                enable = 'off';
            else
                enable = 'on';
            end
            handles.popup(i) = uicontrol(fig, ...
                'Style','popupmenu', ...
                'BackgroundColor',[1,1,1], ...
                'String',listItems, ...
                'Value',value,...
                'Enable',enable,...
                'Position',[135 fieldHt*(numRows-i)+footer+10 350 20], ...
                'HorizontalAlignment','Left', ...
                'CallBack', ...
                ['mrdInsertGUI(''pop_callback'', gcbo, [], guidata(gcbo), ',num2str(i),');']);   
        elseif(strcmp(handles.columnInfo{i}.type,'enum'))
            % if this column is of type 'enum', then we have a limited list of values to 
            % pick from.  So, we'll also use a pull-down menu.
            % Because MySQL puts the enum options list in the 'size' attribute of
            % a column's metadata, we get that list from the 'size' field.
            if(~isempty(handles.values{i}))
                value = strmatch(handles.values{i}, handles.columnInfo{i}.size);
            else
                value = 1;
            end
            if(handles.valueFixed(i))
                enable = 'off';
            else
                enable = 'on';
            end
            handles.popup(i) = uicontrol(fig, ...
                'Style','popupmenu', ...
                'BackgroundColor',[1,1,1], ...
                'Value',value,...
                'Enable',enable,...
                'String',handles.columnInfo{i}.size, ...
                'Position',[135 fieldHt*(numRows-i)+footer+10 350 20], ...
                'HorizontalAlignment','Left', ...
                'CallBack', []);   
        else
            % no link and not an enum- just throw up an edit text box
            if(~handles.thisID)
                % Set a default value
                if(strcmp(handles.columnInfo{i}.type,'date'))
                    [y,m,d] = datevec(now);
                    handles.values{i} = sprintf('%0.4d-%0.2d-%0.2d', y, m, d);
                elseif(strcmp(handles.columnInfo{i}.type,'datetime'))
                    [y,m,d,h] = datevec(now);
                    handles.values{i} = sprintf('%0.4d-%0.2d-%0.2d %0.2d:00:00', y,m,d,h);
                end
            end
            if(handles.valueFixed(i))
                enable = 'off';
            else
                enable = 'on';
            end
           handles.ed(i) = uicontrol(fig, ...
                'Style','edit', ...
                'BackgroundColor',[1,1,1], ...
                'Enable',enable,...
                'String',handles.values{i}, ...
                'Position',[135 fieldHt*(numRows-i)+footer+10 350 20], ...
                'HorizontalAlignment','Left', ...
                'CallBack', ['mrdInsertGUI(''edit_callback'',gcbo,[],guidata(gcbo));']);
        end
    end
    
    % DO THE CROSS_LINK BUTTONS
    for i=[1:length(handles.XLinks)]
        index = i+numFields;
        handles.edt(index) = uicontrol(fig, ...
            'Style','text', ...
            'String',['Cross-link via ',handles.XLinks{i}{1},':'], ...
            'HorizontalAlignment','Right', ...
            'Position',[10 fieldHt*(numRows-index)+footer+6 200 20]);
        if(handles.thisID)
            numLinks = mrdCount(handles.XLinks{i}{1},{handles.XLinks{i}{2},num2str(handles.thisID)});
            txt = ['(item currently has ',num2str(numLinks),' cross-links)'];
            enabled = 'on';
        else
            txt = ['(cross-linking disabled until item is inserted)'];
            enabled = 'off';
        end
        handles.xnoteText(i) = uicontrol(fig, ...
            'Style','text', ...
            'String',txt, ...
            'HorizontalAlignment','Left', ...
            'Position',[285 fieldHt*(numRows-index)+footer+6 200 20]);
        handles.xlinkButton(i) = uicontrol(fig,...
            'Style','push',...
            'Position',[215 fieldHt*(numRows-index)+footer+8 60 20],...
            'String','Add Link',...
            'Enable',enabled,...
            'CallBack', ['mrdInsertGUI(''xlink_callback'',gcbo,[],guidata(gcbo),',num2str(i),');']);
    end
    if(~handles.thisID)
        txt = 'Insert';
    else
        txt = 'Update';
    end
    % Go
    handles.pb1 = uicontrol(fig,...
        'Style','push',...
        'Position',[160 5 80 25],...
        'String',txt,...
        'CallBack', ['mrdInsertGUI(''go_callback'', gcbo, [], guidata(gcbo));']);
    
    % Exit
    handles.pb2 = uicontrol(fig,...
        'Style','push',...
        'Position',[280 5 80 25],...
        'String','Close',...
        'CallBack', ['mrdInsertGUI(''close_callback'', gcbo, gcbf, guidata(gcbo));']);
    
    guidata(fig, handles);
    
    % We override the standard closereq function for the figure, so that we can
    % do any necessary clean-up.
    % NOTE- this is dangerous- it can cause lock-ups!
    set(fig,'CloseRequestFcn',['mrdInsertGUI(''close_callback'', gcf, [], guidata(gcf));']);
    
    if nargout > 0
        varargout{1} = fig;
    end
    
    if(handles.closeDB)
        handles.closeDB = 0;
        handles.db.close;
    end
end

% **************************************************************
function varargout = go_callback(h, eventdata, data, varargin)
%evalin('base','d=data');
for i=[1:length(data.values)]
    if(data.fieldLinks(i))
        % non-zero means that we have a pop-up for linked fields
        index = get(data.popup(i),'Value');
        % We get the actual database id number from our linkedItemIDs list.
        data.values{i} = data.linkedItemIDs{i}{index};
    elseif(data.popup(i))
        % if it's a pop-up, but not a linked field, then it must be an 'enum' type.
        % So, we just copy  the value straight away.
        str = get(data.popup(i),'String');
        data.values{i} = str{get(data.popup(i),'Value')};
    else
        % If it's not a pop-up at all, then it's a simple edit text field.
        data.values{i} = get(data.ed(i),'String');
    end
    
end;
[res,id] = mrdInsert(data.table, data.values, data.columnNames);
if(res>=1)
    %uiwait(warndlg('Database successfully updated.', 'MrData', 'modal'));
    closereq;
    if(id)
        % there's a subtly here.  If the insert that we just did returns something
        % meaningful for id, then it's a table with an auto-increment primary key.
        % We want to allow further updates to those kinds of tables.  However, if we
        % get id=0 back, then the table updated has no primary key.  This is quite likely
        % a cross-link table, so we don't re-call mrInsertGUI.  Sounds like a hack, and
        % it is!  But, it does make life a bit easier for the user.
        mrdInsertGUI(data.table, id);
    end
else
    warndlg('Database update failed!', 'MrData Insert Failed');
end;


% **************************************************************
function varargout = pop_callback(h, eventdata, data, popupNum)
%
% This gets called when the user selects something from the pop-up
% list, which is a list of items pulled from a linked table.  In addition
% to the item list, is an option to 'insert new item' (option #2).  This
% option allows the user to insert a new field into the table that is linked
% to the current table.  It does this by calling mrInsertGUI again, to launch
% a 'child' insert process.
%
% The main issue here is that, once the user enters the new data with the
% child process, the pop-up menu list of the 'parent' should be updated to 
% reflect the new item list.  We currently try to do this by making the 
% child modal with 'uiwait'.  However, this doesn't always work.
%
% RFD

if(get(data.popup(popupNum),'Value')==2)
    numItems = length(get(data.popup(popupNum), 'String'));
    uiwait(mrdInsertGUI(data.links{data.fieldLinks(popupNum)}{3}));
    %uiwait(warndlg('Now!', 'MrData', 'modal'));
    itemCell = mrdSelect(data.links{data.fieldLinks(popupNum)}{3}, '', [1:3]);
    items = cell(size(itemCell,1)+1,1);
    data.linkedItemIDs{popupNum} = {};
    items{1} = ['Select from "',data.links{data.fieldLinks(popupNum)}{3},'"'];
    items{2} = 'Create new record';
    data.linkedItemIDs{popupNum}{1} = '0';
    data.linkedItemIDs{popupNum}{2} = '0';
    for j=[1:size(itemCell,2)]
        data.linkedItemIDs{popupNum}{j+2} = itemCell{j}{1};
        items{j+2} = implode(' ',itemCell{j});
    end
    set(data.popup(popupNum), 'String', items);
    if(length(get(data.popup(popupNum), 'String')) > numItems)
        set(data.popup(popupNum), 'Value', size(itemCell,2)+2);
    end
end;


% **************************************************************
function varargout = xlink_callback(h, eventdata, data, xlinkNum)
%
% This allows the user to insert a new field into the cross-link table.
% It does this by calling mrInsertGUI again, to launch a 'child' insert process.
%
%
% RFD
%disp(data.XLinks{xlinkNum});
%disp(num2str(data.thisID));
uiwait(mrdInsertGUI(data.XLinks{xlinkNum}{1},{data.XLinks{xlinkNum}{2},num2str(data.thisID),'1'}));
numLinks = mrdCount(data.XLinks{xlinkNum}{1},{data.XLinks{xlinkNum}{2},num2str(data.thisID)});
txt = ['(item currently has ',num2str(numLinks),' cross-links)'];
set(data.xnoteText(xlinkNum),'String',txt);
return;


% **************************************************************
function edit_callback(h, eventdata, data)
data.dirty=1;
guidata(gcbf, data);
return;


% **************************************************************
function close_callback(h, eventdata, data)

if(data.dirty)
    buttonName = questdlg(['Unsaved Changes! Close "', data.table, '" anyway?'], 'MrData', 'Yes', 'No', 'Yes');
    if(strcmp(buttonName,'Yes'))
        closereq;
    end
else
    closereq;
end
return;


