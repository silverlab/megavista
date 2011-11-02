function uSphere = unitSphere(samp)
% Return 3-vectors sampled on the unit sphere
%
%    uSphere = unitSphere(samp)
%
% Example:
%   u = unitSphere;
%   surf(u(1,:),u(2,:),u(3,:))
%

error('Obsolete')
return;

if ieNotDefined('samp'), samp = 0.2; end

u = (-pi:samp:pi); v = (-pi/2:samp:pi/2);
[U,V] = meshgrid(u,v); U = U(:); V = V(:);
uSphere = [cos(U).*cos(V), sin(U).*cos(V), sin(V)]';
return;
