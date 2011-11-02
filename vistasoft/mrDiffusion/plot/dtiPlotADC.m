function hdl = dtiPlotADC(ADC,bvecs)
%Plot directional ADC vectors
%
%  hdl = dtiPlotADC(ADC,bvecs,alpha)
%
% ADC:   Apparent diffusion coefficients
% bvecs: Direction (unit length) of diffusion data
% alpha: Transparency
%
% The signal loss equation is 
%
%    Sdir = S0 exp(-b ADC), so
%    ADC = -(1/b)*ln(Sdir / S0)
%
% where S0 is the b=0 measurement
%
% See also: dtiRenderAdcEllipsoids, covEllipsoid 
%
% (c) Stanford VISTA Team

hdl = mrvNewGraphWin; 
tmp = diag(ADC)*bvecs;
covEllipsoid(tmp,2,hdl);  % This is not necessarily the same size as the diffusion tensor 
set(hdl,'Name','dtiPlotADC');

% If some day you want to edit the alpha or other properties of the
% surface, you can find the surface object this way:
%  c = get(gca,'Children');
%  types = get(c(:),'Type');
%  idx = strfind(types,'surface');
%  set(c(2),'FaceAlpha',0.4)

% T = delaunay3(tmp(:,1),tmp(:,2),tmp(:,3)); 
% camlight;
% lighting phong;
% material shiny;
% set(gca, 'Projection', 'perspective');
% cmap = autumn(255);
% axis equal, colormap([cmap; .25 .25 .25]);
% tetramesh(T,tmp,'FaceAlpha',alpha,'EdgeAlpha',0.1);
% axis on; grid on; axis equal; 


return;