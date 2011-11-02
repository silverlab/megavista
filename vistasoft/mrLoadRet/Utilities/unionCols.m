function [c,ia,ib] = unionCols(a,b)
%
% function [c,ia,ib] = unionCols(a,b)
%
% c is returned as distinct columns found in either matrix a or b (no repetitions)
%
% ia, ib are returned as a vector of column indices (of the input matrices)
% that were used to create c.
% 
% union builtin can only operate on rows, so unionCols transposes
% input using union(a',b','rows') to find distinct values.
%
% example:
% a = [1 2 3; 3 2 1; 1 2 3]
% b = [3 2 1; 1 2 1; 3 2 1]
% c = unionCols(a,b) 
%
% See also INTERSECTCOLS, UNION
%
% remus 5/2007 (based on Heeger's intersectCols)

[cTrans,ia,ib] = union(a',b','rows');

c = cTrans';

return
