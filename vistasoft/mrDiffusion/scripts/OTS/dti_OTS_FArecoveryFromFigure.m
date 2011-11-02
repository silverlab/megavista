% How to estimate average FA from a figure plotting a histogram of FA even
% if "Fiber Summary" says average FA = NaN
%
% DY 11/2/2007

h = gcf % Activate that figure, and get it's handle
h_children = get(h,'Children') % Get the children of this figure

% Find out which one is the right axes handle (should have x from 0 - 600,
% and y from 0 - 0.8, etc, similar to the FA histogram)
get(h_children(1))
get(h_children(2))
get(h_children(3))
get(h_children(4))
get(h_children(5))
get(h_children(6))

% Child of this child (grandchild) is the handle containing the actual data
h_grandchild_6 = get(h_children(6),'Children')

% Store X and Y data
fa_x = get(h_grandchild_6,'XData')
fa_y = get(h_grandchild_6,'YData')

% Check that it's the right data
figure; plot(fa_x,fa_y)

% Estimate mean FA -- this is tricky, because the data is stored in a weird
% way, such that each column contains what you want, but has a dimension of
% four rows in order to represent/draw the 'bar' of the histogram for that
% point. The code below will take out the max Y for each 'bar', then
% multiply this with the appropriate FA value for the 'bar' (X). It then
% takes a weighted average. 

fa_y = max(fa_y)
fa_x = fa_x(1,:)
sum(fa_x.*fa_y)/sum(fa_y)