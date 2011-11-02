function windowID = mrmStart(windowID,host)
% Start the mrMesh server on your platform.  
%
%  windowID = mrmStart(windowID,host)
%
% Runs for PCWIN and GLNX86. 
%
%  To start the server without opening a window, use
%       windowID = mrmStart(-1,'localhost')
%  or   mrmStart;
%
%  To start the server and open window 3, use
%       windowID = mrmStart(3,'localhost')
% or    windowID = mrmStart(3);
%
% History
%  Author: Wandell 
%  AG, 2005/01/17 Added MAC srvPath
%  LMP, 2011/06/03 Added the path to a centos mesh server for Centos linux.
%
% (c) Stanford Vista, 2008

if ieNotDefined('windowID'), windowID = -1; end
if ieNotDefined('host'), host = 'localhost'; end

switch computer
    case {'PCWIN', 'PCWIN64'}
        srvPath = which('mrMeshSrv.exe');
        dos([srvPath ' &']);
    case {'GLNX86'}
        srvPath = which('mrMeshSrv.glx');
        unix(sprintf('%s &', srvPath));
    case {'GLNXA64'}
        % check whether we are using fedora, and if so, what version
            [s,r]=unix('cat /proc/version | grep fc14.x86_64'); %#ok<*ASGLU>
            [t v] = unix('cat /proc/version | grep centos'); %#ok<*ASGLU>
            if ~isempty(strfind(r,'fc14.x86_64')), 
                srvPath = which('mrMeshSrv_FC14.glxa64');
            elseif ~isempty(strfind(v,'centos'))
                srvPath = which('mrMeshSrv_Centos.glxa64');
            else
                srvPath = which('mrMeshSrv.glxa64');
            end
            unix(sprintf('%s &', srvPath));
        
    case 'MAC'
        srvPath = which('mrMeshServer.app');
        srvPath = [srvPath '/Contents/MacOS/mrMeshServer'];
        eval(['! ' srvPath ' &']);
    otherwise
        error(['Platform "' computer '" is not supported!']);
end

if windowID >= 0
    % Some annoying inter-process communication pause.  Do not remove.  Ask
    % Ress or Bob about this.
    pause(2); 
    windowID = mrMesh(host, windowID, 'refresh'); 
    pause(1);
else
    windowID = -1;
end

return
