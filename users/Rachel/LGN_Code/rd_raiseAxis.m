function pos = rd_raiseAxis(h, amt)
%
% function pos = rd_raiseAxis(h, amt)
%
% h is the axis handle (eg. gca)
% amt is the amout by which to multiply the height value of the position

if nargin==1
    amt = 1.27;
end

pos = get(h,'Position');
pos(2) = pos(2)*amt;
set(gca,'Position',pos);