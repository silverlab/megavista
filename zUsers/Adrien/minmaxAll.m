function [themin, themax] = minmaxAll(matrix)
%-----------------------------------------------------------------
% Outputs the min of a matrix and its max, across all values
%-----------------------------------------------------------------
% Adrien Chopin, 2015
%-----------------------------------------------------------------
themin = min(matrix(:));
themax = max(matrix(:));
