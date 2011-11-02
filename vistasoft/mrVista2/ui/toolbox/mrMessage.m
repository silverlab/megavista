function msgHdl = mrMessage(str,HorizontalAlignment,figPos,fontSize)
%
%   msgHdl = mrMessage(str,[HorizontalAlignment],[figPos],[fontSize])
%
% Author: BW
% Purpose:
%   Display an information message to help the user
%   You can set the text alignment ('center' is default).
%   You can set the figure position (normalized coordinates.  Default is
%   upper right of the screen and fairly small: [0.8, 0.8, 0.16, 0.1];
%
% Example:
%
%   msgHndl = mrMessage('Help me','left');
if ieNotDefined('fontSize'), fontSize = 12; end
if ieNotDefined('HorizontalAlignment'), HorizontalAlignment = 'center'; end
if ieNotDefined('figPos'), figPos = [0.8   0.8    0.16    0.1]; end
if isa(figPos,'char')
    switch lower(figPos)
        case {'middle','center'}
            figPos = [0.4   0.4    0.16    0.1]; 
        case {'upperright','ur'}
            figPos = [0.8   0.8    0.16    0.1]; 
        case {'upperleft','ul'}
            figPos = [0.8   0.1    0.16    0.1]; 
        case {'uppercenter','uc'}
            figPos = [0.8   0.4    0.16    0.1]; 
    end
end

curFig = gcf;
msgHdl = mrMessageBox;
set(msgHdl, 'Position', figPos, 'Color', 'w');

guiH = guihandles(msgHdl);
mrMessageBox('setMessage', msgHdl, [], guiH, str);
set(guiH.txtMessage,'HorizontalAlignment', HorizontalAlignment, ...
                    'FontSize', fontSize, 'BackgroundColor', 'w');

figure(curFig);

return;
