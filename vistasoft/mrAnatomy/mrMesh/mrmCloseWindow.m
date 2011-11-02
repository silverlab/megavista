function status = mrmCloseWindow(windowID,host)
%
%  status = mrmCloseWindow(windowID,host)
%
%Author: Wandell
%Purpose:
%   Close a window on the host.  (If the server has not been started, we do
%   that, too).
%
% Example:
%  status = mrmCloseWindow(6,'localhost')
%  status = mrmCloseWindow(windowID,'localhost')
%  status = mrmCloseWindow(windowID)

if ieNotDefined('host'), host = 'localhost'; end

[windowID,status,res] = mrMesh(host, windowID, 'close'); 

return;
