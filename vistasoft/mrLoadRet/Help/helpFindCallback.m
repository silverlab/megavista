function cb = helpFindCallback(V)
%
% cb = helpFindCallback([view, handle or menu label]);
%
% Find out what the callback text is to a menu selection
% in a GUI. The input argument can be a mrVista 1.0 view, a
% handle to a figure, or text from the label on the menu item.
% The default value is the handle to the current figure.
%
% If either a view or a figure handle is passed, the selected
% figure is briefly turned yellow, and the user is prompted to 
% select the menu item for which they want to get the 
% callback text.  NOTE: this temporarily modifies the callback
% to all the figure's menus, so if it crashes in execution, it 
% might screw up the selected figure and the figure will need
% to be re-created.
% 
% If a label text is provided, looks for a menu containing
% a case-insensitive match for that text, and returns the
% callback to the first such menu found. 
%
% Returns the text in cb, and prints it out in the command window.
% If not control is found, returns an empty string without crashing.
%
%
% ras, 11/07/2005.
if ~exist('V', 'var') || isempty(V), V = gcf; end

cb = '';

if isstruct(V)
    % view specified -- not yet implemented
    
elseif ishandle(V)
    % handle to figure -- get child uimenus
    h = getChildUimenus(V);
    
    % record callbacks to each item
    cbList = get(h, 'Callback');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set up a uiwait / uiresume dialog %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % set figure yellow for highlighting
    figColor = get(V, 'Color');
    set(V, 'Color', 'y');
    
    % put up a message
    msg = 'Select the menu item whose callback you''d like.';
    hmsg = mrMessage(msg);    
    
    % temporarily set all callbacks to be uiresume
    for i = 1:length(h)
        if ~isempty(cbList{i}) % ignore submenus
            set(h(i), 'Callback', sprintf('SEL = %i; uiresume;',i)); 
        end
    end
    
    % Let the user pick the desired item
    uiwait;
    
    % find the selected menu and get that callback
    SEL = evalin('base', 'SEL');
    cb = cbList{SEL};
        
    % restore the menu callbacks / other settings
    for i=1:length(h), set(h(i), 'Callback', cbList{i}); end
    set(V, 'Color', figColor);
    close(hmsg);        
    
    % report the callback in the command window:
    fprintf('Selected Menu Item: \n ');
    fprintf('Label: %s \n ', get(h(SEL), 'Label'));
    fprintf('Handle: %f \n Callback: %s\n', h(SEL), cb); 
    
    % clean up the temp variable
    evalin('base', 'clear SEL');
    
elseif ischar(V)
    % label for menu item 
	h = findobj('Label', V);
	
	fprintf('%i objects found with label %s', length(h), V);
	
	for ii = 1:length(h)
		fprintf('Selected Menu Item: \n ');
		fprintf('Label: %s \n ', get(h(ii), 'Label'));
	    fprintf('Handle: %f \n Callback: %s\n', h(ii), get(h(ii), 'Callback')); 
	end
	
	if ~isempty(h)
		cb = get(h, 'Callback');
	end

    
else
    help(mfilename);
    error('Invalid argument format.')
end


return
% /----------------------------------------------------------------/ %




% /----------------------------------------------------------------/ %
function h = getChildUimenus(par)
% h = getChildUimenus(par);
% Find all uimenus that belong to a parent figure or uimenu, 
% or a submenu of the parent, and return as a vector in h.
% ras, 11/05
h = findobj('Parent', par, 'Type', 'uimenu');
for i = h(:)'
    subh = getChildUimenus(i); 
    h = [h; subh];
end
return

