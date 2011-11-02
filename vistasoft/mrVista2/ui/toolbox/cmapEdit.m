function map = cmapEditOld(map,varargin);
% Edit a color map, with some different options from CMAPEDITOR.
%
%  map = cmapEditOld(map);
%
% This creates a UI with a figure showing the input colormap,
% allowing users to click on each color and manually set the color.
% Closing the UI figure causes the updated map to be returned.
%
% ras, 10/2005.
%      06/2006: made new version, renamed this one cmapEditOld.
if notDefined('map'), map = hot(256); end

% this is a convoluted switch -- if the optional arg 'update' 
% is entered, will update the UI rather than starting a new one.
% (It's used as a button-down function by the UI):
if ~isempty(varargin) & isequal(lower(varargin{1}),'update')
    cmapEditUpdate; return;
end

%%%%%%%%%%%%%%%BELOW THIS POINT SETS UP THE UI %%%%%%%%%%%%%%%%%%%%%%%
h=figure('Name','User Colormap','Units','normalized',...
       'Position',[.2 .2 .5 .3]); 

nColors = size(map,1);   
       
% put up an image of a colorbar w/ instrux
bar = repmat(1:nColors,20,1);
himg = imagesc(bar); axis equal; axis off; colormap(map);
title(['Click on each point to edit the color. '...
      'Use cmapeditor for more options. Close figure when done.'],...
      'FontSize',10,'FontWeight','bold');

% also add menus to set preset color bars.
mapNames = mrvColorMaps;
mapNames = mapNames(1:end-1); % remove the 'user' option
uimenu('Label','        ');   % spacer
hm=uimenu('Label','Preset Colormaps','ForegroundColor','b');
for i = 1:length(mapNames)
    cb = sprintf('set(gcf,''Colormap'',mrvColorMaps(%i,%i))',i,nColors);
    uimenu(hm,'Label',mapNames{i},'Callback',cb);
end
      
% set a button-down function to edit colors
% hnggh ... have to evaluate the above in the callback workspace:
set(himg, 'ButtonDownFcn', 'cmapEdit([],''update'');');

% do a uiwait/uiresume
set(gcf,'CloseRequestFcn','uiresume;');
uiwait;    

map = get(gcf,'Colormap');
closereq;

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function cmapEditUpdate;
% allows the user to set one color in the cmap using uisetcolor,
% and updates the figure's colormap.
map = get(gcf,'Colormap');
pt = get(gca,'CurrentPoint');
x = round(pt(1));
map(x,:) = uisetcolor(map(x,:));
set(gcf,'Colormap',map);
return
