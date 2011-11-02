function [c,ia,ib] = intersectCols(a,b)
%
% function [c,ia,ib] = intersectCols(a,b)
%
% Uses intersect(a',b','rows') to intersect colums.
%
% djh, 8/4/99
[cTrans,ia,ib] = intersect(a',b','rows');
c = cTrans';
return
