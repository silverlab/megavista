function [fa, md, rd, ad, cl, SuperFiber, fgClipped] = ...
    dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes, dFallOff)
%   Compute a weighted average of a variable (FA/MD/RD/AD) in a track segment
%
%  [fa, md, rd, ad, SuperFibersGroup,fgClipped] = ...
%    dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes, [dFallOff])
%
%   From a fiber group (fg), and diffusion data (dt), compute the weighted
%   2 value of a diffusion property (taken from dt) between the two ROIS at
%   a NumberOfNodes, along the fiber track segment between the ROIs,
%   sampled at numberOfNodes point.
% 
% INPUTS:
%       fg            - fiber group structure.
%       dt            - dt6.mat structure
%       roi1          - first ROI for the fg
%       roi2          - second ROI for the fg
%       numberOfNodes - number of samples taken along each fg
%       dFallOff      - rate of fall off in weight with distance. More
%                       comments here.
% 
% OUTPUTS:
%       fa         - Weighted fractional anisotropy
%       md         - Weighted mead diffusivity
%       rd         - Weighted radial diffusivity
%       ad         - Weighted axial diffusivity
%       cl         - * 
%       superFiber - structure containing the core of the fiber group
%       fgClipped  - fiber group clipped to the two ROIs
% 
% WEB RESOURCES:
%   mrvBrowseSVN('dtiComputeDiffusionPropertiesAlongFG')
%   http://white.stanford.edu/newlm/index.php/Diffusion_properties_along_trajectory
%   See dtiFiberGroupPropertyWEightedAverage
% 
% EXAMPLE USAGE:
%
% HISTORY: 
%  ER wrote it 12/2009
% 
% (C) Stanford University, VISTA Lab

%%
display('Clipping fibers to ROIs');
% For arcuate, this will still retain some weirdos...
fgClipped = dtiClipFiberGroupToROIs(fg,roi1,roi2);
if notDefined('dFallOff'), dFallOff = 1; end

% Once clipped and reoriented, compute weighted averages for eigenvalues
display('Creating a superfiber');
[myValsFgWa, SuperFiber, weightsNormalized] = ...
    dtiFiberGroupPropertyWeightedAverage(fgClipped, dt, numberOfNodes, 'famdadrdShape',dFallOff);

% Pull out specific properties
fa = myValsFgWa(:, 1);
md = myValsFgWa(:, 2);
ad = myValsFgWa(:, 3);
rd  =myValsFgWa(:, 4);
cl = myValsFgWa(:, 5);
% cp=myValsFgWa(:, 6);
% cs=myValsFgWa(:, 7);


return
