function links = mrdGetLinks(table, db, crossLinkFlag)
% 
% links = mrdGetLinks(table, db, crossLinkFlag)
%
% MrData function to search the links table to find all the
% foriegn keys to which the specified table is linked (if any).
%
% if crossLinkFlag is set, this function returns crosslinks instead of
% direct links.
%
% If no connection is supplied, we will open and close our own.
% (If you supply one, we won't close it.)
%
% RETURNS: the found links in a cell array, as:
%   {'fromTable','fromField','toTable','toField'},{'fromTable','fromField','toTable','toField'},...
%
% 2001.01.25 Bob Dougherty <bob@white.stanford.edu>
%

closeDB = 0;
if(~exist('db', 'var') | isempty(db))
    db = mrdConnect;
    closeDB = 1;
end
if(~exist('crossLinkFlag', 'var'))
    crossLinkFlag = 0;
end

if(crossLinkFlag)
    query = ['SELECT * FROM xLinks WHERE toTable="',table,'" AND fromTable LIKE "x%"'];
else
    query = ['SELECT * FROM xLinks WHERE fromTable="',table,'"'];
end

[links, colNames] = mrdQuery(query, db);

if(closeDB)
    mrdDisconnect(db);
end
return;