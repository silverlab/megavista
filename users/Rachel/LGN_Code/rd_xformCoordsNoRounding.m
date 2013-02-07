function newCoords = rd_xformCoordsNoRounding(coords,Xform)

% newCoords = rd_xformCoordsNoRounding(coords,Xform)
%
% Transforms coords using Xform

% ROIcoords: 3xN matrix of coordinates (y,x,z).
% Xform: 4x4 homogeneous transform
%
% newROIcoords: 3xN matrix of (y,x,z) 
%
% Modified from mrVista function xformROIcoords.m
%
% Rachel Denison
% 2013 Feb 6

if ~isa(coords, 'double'), coords = double(coords); end

% Convert ROI coords to homogenous coordinates, by adding a fourth
% row of 1's, and transform.
newCoords = ones(4,size(coords,2));
newCoords(1:3,:) = coords;
newCoords = Xform * newCoords;

newCoords = newCoords(1:3,:);

return;

%%%%%%%%%%%%%%
% Debug/test %
%%%%%%%%%%%%%%

ROIcoords = [0; 0; 0];
ROIcoords = [1 2 3 4;
	         1 1 1 1;
	         1 1 1 1];
Xform = [1 0 0 0;
	     0 1 0 0;
	     0 0 1 0.5;
	     0 0 0 1];
xformROIcoords(ROIcoords,Xform)
