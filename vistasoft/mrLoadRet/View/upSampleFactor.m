function n = upSampleFactor(view, scan);
%
% n = upSampleFactor(view,scan);
%
% gives the relative size of the anatomical inplanes divided by the size of
% the functional data. n is a 3-element vector with these values in the x,
% y, and z directions. 
%
% ras, 09/2005: now does what it says and returns a 3-vector. This may
% affect other things, so keeping it local for awhile...
% ras, 09/2008: having this depend on the scan introduces crazy errors.
% There are deep issues which would need to be resolved before this
% parameter can vary between scans. So, moving forward, we always use scan
% 1, and assume this is the same for all data in a session.
if nargin<2, scan=1; end

% It used to warn you when the x, y, and z-direction factors weren't equal,
% but I think I've dealt with all the downstream consequences of this, so I
% disabled it. -ras, 01/2004.
switch lower(view.viewType)
    case {'inplane' 'flat'}
        n = viewSize(view) ./ dataSize(view,1);
        
    case {'volume' 'gray'}
        n = [1 1 1];
end
return