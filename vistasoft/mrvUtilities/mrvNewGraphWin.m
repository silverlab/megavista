function figHdl = mrvNewGraphWin(ftitle)
% Open a new graph window  
%
%    figHdl = mrvNewGraphWin([title])
%
% A stanford mrVIsta graph window figure is opened and its handle is
% returned 
%
% (c) Stanford VISTA Team

figHdl = figure;

if notDefined('ftitle')
    ftitle = 'mrVista: ';
else
    ftitle = sprintf('mrVista: %s',ftitle);
end
set(figHdl,'Name',ftitle,'NumberTitle','off');

set(figHdl,'Color',[1 1 1]);

return;
