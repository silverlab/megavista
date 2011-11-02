function [found,colNames] = mrdSearch(searchString, tables, fields, db)
% 
% [found,colNames] = mrdSearch(searchString, [tables], [fields], [dbConnection])
%
% MrData function to search the default database.
%
% If a list of fields is supplied (cell array), only those fields will be
% searched.  Otherwise, all fields will be searched.
%
% If no connection is supplied, we will open and close our own.
% (If you supply one, we won't close it.)
%
% RETURNS: the search results as numTables cell-arrays each rows X cols, and the
%          column names as numTables cell arrays, each of length numCols.
%
% 2001.01.23 Bob Dougherty <bob@white.stanford.edu>
% 2001.04.05 Bob: generalized it a bit to allow searching on specific fields.
%

if(~exist('fields', 'var'))
    fields = {};
end
if(~exist('tables', 'var'))
    tables = {};
end

closeDB = 0;
if(~exist('db', 'var'))
    db = mrdConnect;
    closeDB = 1;
end

nocell = 0;
if(~iscell(tables))
    nocell = 1;
    tables = {tables};
end
if(~iscell(fields))
    fields = {{fields}};
end

if(isempty(tables))
    tables = mrdGetTables(db,'x');
end

for(ii=[1:length(tables)])
    % start to build the main query
    query = ['SELECT * FROM ',tables{ii},' WHERE 0'];
    % if no fields were supplied, we do a query to get all the fields and use those.
    if(ii>length(fields) | isempty(fields{ii}))
        f = mrdGetColumns(tables{ii}, db);
    else
        f = fields{ii};
    end
    for(jj=1:length(f))
        query = [query ' OR ' tables{ii} '.' f{jj} ' LIKE "%' searchString '%"'];
    end
    [found{ii}, colNames{ii}] = mrdQuery(query, db);
end

% If we are called with a single table name (*not* a cell array of table
% names), then we return a simple, non-cell result.
if(nocell)
    found = found{1};
    colNames = colNames{1};
end

if(closeDB)
    
end