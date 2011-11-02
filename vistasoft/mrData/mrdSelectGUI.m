function id = mrdSelectGUI(varargin)
% 
% id = mrdSelectGUI(tables)
%
% MrData GUI function to select a row from the specified table(s).  Allows the
% user to add a new row (by calling mrdInsertGUI).
%
% We will open and close our own connection.
%
% RETURNS: the result- 0 for failure. Otherwise, the selected row's id.
%
% 2001.04.04 Bob Dougherty <bob@white.stanford.edu>
%

if (nargin>1 & ischar(varargin{1})) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    try
        feval(varargin{:}); % FEVAL switchyard
    catch
        disp(lasterr);
    end
else
    tables = varargin{1};
    
    import java.sql.*;
    import java.io.*;
    
    fig = figure;
    
    h = guihandles(fig);
    h.fig = fig;
    h.db = mrdConnect;
    if(~iscell(tables))
        h.tables = {tables};
    else
        h.tables = tables;
    end
    
    numTables = length(h.tables);
    
    % Use system color scheme for figure:
    set(fig,'WindowStyle','modal');
    set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
    set(fig,'Name',['MrData Select: ',h.tables{1}]);
    
    % This will be a cell array of numeric arrays, one for each field.
    % It will contain the database index ('id', always the first column by convention)
    % for each item in the popup list.
    h.itemIDs = {};
    
    % flag to indicate ok/cancel
    h.ok = 0;  
    
    footer = 40; % pixel-height of footer region (which contains the pushbuttons)
    fieldHt = 30; % pixel-height of each text entry field
    
    pos = get(fig,'Position');
    pos(3) = 500;
    pos(4) = fieldHt*numTables+footer;
    set(fig,'Position',pos);
    
    for(i=[1:numTables])
        h.text(i) = uicontrol(fig, ...
            'Style','text', ...
            'String',['Select from ',h.tables{i},':'], ...
            'HorizontalAlignment','Right', ...
            'Position',[10 fieldHt*(numTables-i)+footer+8 120 20]);
        
        % Create pop-up menu of choices from the table
        % For this list, we just grab the first 3 columns.  Hopefully, that's enough
        % for the user to decide which item they want.
        itemCell = mrdSelect(h.tables{i}, '', [1:3], h.db);
        items = cell(size(itemCell,1)+2,1);
        
        items{1} = 'Select an item';
        items{2} = 'Create new record';
        
        % these first two items in the pull-down list are 'select an item' and
        % 'create new item', so they don't get real database indices.
        h.itemIDs{i}{1} = '0';
        h.itemIDs{i}{2} = '0';
        for j=[1:size(itemCell,1)]
            h.itemIDs{i}{j+2} = itemCell{j,1};
            items{j+2} = implode(' ',{itemCell{j,:}});
        end
        
        h.popup(i) = uicontrol(fig, ...
            'Style','popupmenu', ...
            'BackgroundColor',[1,1,1], ...
            'String',items, ...
            'Position',[135 fieldHt*(numTables-i)+footer+10 350 20], ...
            'HorizontalAlignment','Left', ...
            'CallBack', ['mrdSelectGUI(''pop_callback'', gcbo, [], guidata(gcbo), ',num2str(i),');']);   
    end % for(i=[1:h.numTables])
    
    % OK
    h.pb1 = uicontrol(fig,...
        'Style','push',...
        'Position',[160 5 80 25],...
        'String','OK',...
        'Enable','off',...
        'CallBack', ['mrdSelectGUI(''done_callback'', gcbo, [], guidata(gcbo), 1);']);
    
    % Cancel
    h.pb2 = uicontrol(fig,...
        'Style','push',...
        'Position',[280 5 80 25],...
        'String','Cancel',...
        'CallBack', ['mrdSelectGUI(''done_callback'', gcbo, [], guidata(gcbo), 0);']);
    
    % We override the standard closereq function for the figure, so that we can
    % do any necessary clean-up.  (Basically, we treat this as a 'Cancel'.)
    %set(fig,'CloseRequestFcn',['h=guidata(gcbo); h.ok=0; guidata(gcbo, h); uiresume;']);
    
    guidata(fig, h);
    
    uiwait(fig);
    
    h.db.close;
    
    % refresh the guidata struct
    h = guidata(fig);

    for i=[1:length(h.tables)]
        if(h.ok)
            id{i} = h.itemIDs{i}{get(h.popup(i),'Value')};
        else
            id{i} = 0;
        end
    end
    if(length(id)==1)
        id = id{1};
    end
    close(fig);
end
return;
    

% **************************************************************
function varargout = pop_callback(fig, eventdata, h, popupNum)
%
% This gets called when the user selects something from the pop-up.  In 
% addition to the item list, is an option to 'insert new item' (option #2).
% This option allows the user to insert a new row into the table by 
% calling mrInsertGUI, to launch a 'child' insert process.
%
% The main issue here is that, once the user enters the new data with the
% child process, the pop-up menu list of the 'parent' should be updated to 
% reflect the new item list.  We currently try to do this by making the 
% child modal with 'uiwait'.  However, this doesn't always work.
%
% RFD

if(get(gcbo,'Value')==2)
    origNumItems = length(get(gcbo,'String'));
    uiwait(mrdInsertGUI(h.tables{popupNum}));
    itemCell = mrdSelect(h.tables{popupNum},'', [1:3], h.db);
    items = cell(size(itemCell,1)+2,1);
    items{1} = 'Select an item';
    items{2} = 'Create new record';
    for(j=[1:size(itemCell,2)])
        h.itemIDs{popupNum}{j+2} = itemCell{j}{1};
        items{j+2} = implode(' ',itemCell{j});
    end
    set(gcbo,'String',items);
    if(length(get(gcbo,'String')) > origNumItems)
        set(gcbo,'Value',size(itemCell,2)+2);
    end
end
% Next, we update the 'OK' button's enabled status.
% We only want it enabled if the user has selected something meaningful for all tables.
selected = zeros(1,length(h.popup));
for(i=[1:length(h.popup)])
    selected(i) = get(h.popup(i),'Value')>2;
end
if(all(selected))
    set(h.pb1,'Enable','on');
else
    set(h.pb1,'Enable','off');
end
guidata(gcbo,h);


% **************************************************************
function varargout = done_callback(fig, eventdata, h, ok)
h.ok = ok; 
guidata(gcbo, h); 
uiresume(gcbf);