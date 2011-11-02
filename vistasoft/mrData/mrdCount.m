function numRows = mrdCount(table, fieldsValues, db)
% 
% numRows = mrdCount(table, [fieldsValues], [dbConnection])
%
% MrData function- returns a count of the number of rows in the table.
% If some fields and corresponding values are provided, they will be used
% to restrict the search.  (Use the format: {'field','value,'field','value',...})
%
% If no connection is supplied, we will open and close our own.
% (If you supply one, we won't close it.)
%
% RETURNS: the number of rows in the specified table matching the (optional) 
%           criteria in fieldsValues.
%
% 2001.04.06 Bob Dougherty <bob@white.stanford.edu>
%

closeDB = 0;
if(~exist('db', 'var'))
    db = mrdConnect;
    closeDB = 1;
end

query = ['SELECT COUNT(*) FROM ',table];
if(exist('fieldsValues','var') & ~isempty(fieldsValues))
    query = [query,' WHERE 1 '];
    for(i=[1:2:length(fieldsValues)])
        query = [query,' AND ',fieldsValues{i},' LIKE "',fieldsValues{i+1},'"'];
    end
end
[data, colNames] = mrdQuery(query, db);

if(isempty(data))
    numRows = 0;
else
    numRows = data{1};
end

if(closeDB)
    mrdDisconnect(db);
end
return;