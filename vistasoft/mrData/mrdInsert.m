function [numUpdated,id] = mrdInsert(table, values, fields, db)
% 
% [numUpdated,id] = mrdInsert(table, values, [fields], [db])
%
% MrData function to insert data into the default database.  If the 
% record specified by the value list already exists, that row will 
% be updated.  Otherwise, a new row will be inserted.
%
% If no connection is supplied, we will open and close our own.
% (If you supply one, we won't close it.)
%
% RETURNS: the result- 0 for failure, 1 for a successful insert, and 
%   >= 1 for a successful update (ie. the number of updated rows.)
%
% 2001.01.24 Bob Dougherty <bob@white.stanford.edu>
%

closeDB = 0;
if(~exist('db', 'var'))
    db = mrdConnect;
    closeDB = 1;
end

% REPLACE is just like INSERT, except that if it finds that the unique key
% specified by the data already exists, it will do an UPDATE instead of INSERT.
query = ['REPLACE INTO ',table,' '];
if(exist('fields', 'var') & ~isempty(fields))
    query = [query,'(',implode(',',fields),') '];
end
query = [query,'VALUES (',implode(',',values,'"'),')'];

numUpdated = mrdQuery(query, db);

% HOW TO FIND THE ID OF THE INSERTED ITEM???
id = mrdQuery('SELECT LAST_INSERT_ID()', db);

if(closeDB)
    mrdDisconnect(db);
end