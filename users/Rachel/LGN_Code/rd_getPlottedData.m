function [xData, yData] = rd_getPlottedData(fH)

if ~exist('fH','var')
    fH = gcf;
end

lineH = findobj(fH, 'type', 'line'); % get handles of lines
xData = get(lineH, 'xdata'); % get x-data
yData = get(lineH, 'ydata'); % get y-data