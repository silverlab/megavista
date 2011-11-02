function tables = mrdGetTables(db, excludeStr)
% 
% tables = mrdGetTables([dbConnection], [excludeStr])
%
% MrData function to get all tables in the default database, 
% except those that begin with 'excludeStr'.
%
% If no connection is supplied, we will open and close our own.
% (If you supply one, we won't close it.)
%
% RETURNS: a cell-array of table names (suitable for future queries).
%
% 2001.01.23 Bob Dougherty <bob@white.stanford.edu>
%

closeDB = 0;
if(~exist('db', 'var'))
    db = mrdConnect;
    closeDB = 1;
end
if(isempty(db))
    warn('could not connect to database.');
end

tables = {};

[tables,colNames] = mrdQuery('SHOW TABLES', db);
if(exist('excludeStr', 'var'))
    tables(strmatch(excludeStr,tables)) = [];
end
if(closeDB)
    mrdDisconnect(db);
end

return
