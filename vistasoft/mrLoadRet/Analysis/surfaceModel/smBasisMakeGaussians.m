function  model = smBasisMakeGaussians(model)
% Create a set of Gaussian basis functions for surface model.
% (see smMain.m)
%
%   model = smBasisMakeGaussians(model)
%
% The basis functions will be generated and then stored with the model. The
% stimulus will also be projected into the basis space and this projection
% will be stored too.

% Get x and y grid matrices that are the size and resolution of the
% stimulus representation
[X, Y]          = smGrid(model);

% Choose some values to specify how densely to fill the space of possible
% gaussians to use as our basis functions
%   These should be derived based on the stimulus size or user inputs. For
%   now they are hard-coded. 
nspokes         =  36;
nrings          =  15;
nsigmas         =  10;

% Get the x,y, sigma values for each basis function
bounds          = [-1 1] * smGet(model, 'stimsize');
[x0,y0, sigma]  = smPolarGrid(bounds,nrings,nspokes, nsigmas);

sigmaMajor  = sigma;
sigmaMinor  = sigmaMajor;
theta       = sigmaMajor * 0; 

% Create the basis functions from their parameters (i.e., convert x,y,s
% into an image of a gaussian)
basisFunctions  = double(rfGaussian2d(X,Y,sigmaMajor,sigmaMinor,theta, x0,y0));

% Set the total size of each basis vector to be 1?
% tmp             = 1./sum(basisFunctions);
% tmp             = ones(size(basisFunctions,1), 1) * tmp(:)';
% basisFunctions  = basisFunctions .* tmp;

% Project the stimulus into our basis space
stimulus        = smGet(model, 'stimulus tseries');
basisProjection = stimulus * basisFunctions;

% Store the results.
model = smSet(model, 'basis functions',  single(basisFunctions));
model = smSet(model, 'basis projection', single(basisProjection));
model = smSet(model, 'nBasisFunctions',  size(basisFunctions, 2));

return


function [X, Y] = smGrid(model)
% [X, Y] = smGrid(model)
%
% Example:  [X, Y] = smGrid(model)

% get stimulus size and resolution
sz  = smGet(model, 'stimulus size');        % degrees (radius)
res = smGet(model, 'stimulus resolution');  % pixels (diameter)

[X, Y] = meshgrid(linspace(-sz, sz, res), linspace(-sz, sz, res));

keep = smGet(model, 'instimwindow');

X = X(keep);
Y = Y(keep);
return

function [x,y,s]=smPolarGrid(bounds,nrings,nspokes, nsigmas)
% polarGrid - make polar grid of points with x-meridians.
%
%  [x,y,s]=smPolarGrid(bounds,nrings,nspokes, nsigmas)
%
% Example: 
%  [x,y,s]=polarGrid([-3 3],8,16,10);
%  plot(x,y,'o');axis equal;
% makes and plots a polar grid between -3 and 3, the rings are log-spaced
% to (roughly) match cortical magnification factor, whereas the spokes are
% linearly distributed.
%
% 2008/08 SOD: wrote it.
% 2010/01 JW: adapted from SOD's function polarGrid.m

if nargin < 4,
    help(mfilename);
    return;
end;

% maximal radius and eccentricity points
rmax = sqrt(sum(bounds.^2));
r = logspace(log10(1),log10(rmax+1),nrings)-1;

% compute angle points
th = linspace(0,2*pi,nspokes+1);
th = th(1:end-1)+pi/4;

% compute sigmas
smin = .1;
smax = 3;
s    = [];
for ii = 1:nrings;
    s = [s logspace(log10(smin),log10(smax+r(ii)),nsigmas)];
end
s = ones(nspokes,1)* s(:)' ;
s = s(:);

th = th(:)*ones(1,nsigmas * nrings);
r  = ones(nspokes * nsigmas,1)*r(:)';

th = [zeros(nsigmas,1);th(:)];
r  = [zeros(nsigmas,1);r(:)];
s  = [logspace(log10(smin),log10(smax),nsigmas)'; s(:)];

% cartesian coordinates
x = r.*cos(th);
y = r.*sin(th);

% limit just in case
keep = x>=bounds(1) & x<=bounds(2) & y>=bounds(1) & y<=bounds(2);
x = x(keep);
y = y(keep);
s = s(keep);
return
