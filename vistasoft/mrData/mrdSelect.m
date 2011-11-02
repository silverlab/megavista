function [rows, colNames] = mrdSelect(tables, whereClause, colNums, db)
% 
% [rows, columnNames] = mrdSelect(tables, [whereClause], [colNums], [dbConnection])
%
% MrData function to do a simple select.  If more than one table name is
% specified (in a cell array), then the specified tables will be joined.
%
% If no connection is supplied, we will open and close our own.
% (If you supply one, we won't close it.)
%
% RETURNS: the results as a numRows X numCols cell-array, and the
%          column names as a numCols cell array.
%
% 2001.01.31 Bob Dougherty <bob@white.stanford.edu>
%
% Example:
%     [rows, columnNames] = mrdSelect('subjects', '', 1:3)
closeDB = 0;
if(~exist('db', 'var'))
    db = mrdConnect;
    closeDB = 1;
end

rows = {};
colNames = {};

if(iscell(tables))
    query = ['SELECT * FROM ',implode(',',tables)];
else
    query = ['SELECT * FROM ',tables];
end
if(exist('whereClause','var') & ~isempty(whereClause))
    query = [query,' WHERE ',whereClause];
end

[rows, colNames] = mrdQuery(query);

if(exist('colNums','var') & ~isempty(colNums))
    colNames = {colNames{colNums}};
    rows = rows(:,colNums);
end

if(closeDB)
    mrdDisconnect(db);
end