function [rows,colNames] = mrdQuery(query, db)
% 
% [rows,colNames] = mrdQuery(query, [dbConnection])
%
% MrData function- runs 'query' on the default database.
%
% If no connection is supplied, we will open and close our own.
% (If you supply one, we won't close it.)
%
% RETURNS: the search results as numTables cell-arrays each rows X cols, and the
%          column names as numTables cell arrays, each of length numCols.
%          However, if there is only one return argument, the result is
%          returned as a struct, with a field for each column.
%
% 2001.04.02 Bob Dougherty <bob@white.stanford.edu>
%
 
closeDB = 0;
if(~exist('db', 'var') | isempty(db))
    db = mrdConnect;
    closeDB = 1;
end

result = mysql(query,'');
if(isstruct(result) & nargout>1)
    colNames = fieldnames(result);
    rows = struct2cell(result)';
else
    colNames = {};
    rows = result;
end

if(closeDB)
    mrdDisconnect(db);
end