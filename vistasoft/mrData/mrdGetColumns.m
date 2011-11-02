function [columnNames,columnData] = mrdGetColumns(table, db)
% 
% [columnNames,columnData] = mrdGetColumns(table, [dbConnection])
%
% MrData function to get all columns of the table in the default database.
%
% If no connection is supplied, we will open and close our own.
% (If you supply one, we won't close it.)
%
% RETURNS: a cell-array of column names (suitable for future queries).
%
% 2001.01.24 Bob Dougherty <bob@white.stanford.edu>
%

closeDB = 0;
if(~exist('db', 'var'))
    db = mrdConnect;
    closeDB = 1;
end

columnNames = {};

[rows,metaColNames] = mrdQuery(['SHOW COLUMNS FROM ',table], db);

columnNames = rows(:,1);
types = rows(:,2);
if(nargout>1)
    for(curCol=1:length(types))
        if(~isempty(types{curCol}))
            % the type field is a string like: 'type(size)'
            % (size is usually the byte-count, but for enums, it's a list of possible values)
            % Also, some types, like 'date' or 'datetime' don't have a size.
            tmpStr = lower(types{curCol});
            pS = findstr(tmpStr, '(');
            pE = findstr(tmpStr, ')');
            if(~isempty(pS) & ~isempty(pE))
                columnData(curCol).type = tmpStr(1:pS(1)-1);
                size = tmpStr((pS(1)+1):(pE(end)-1));
                if(strcmp(columnData(curCol).type,'enum'))
                    columnData(curCol).size = explode(',',size,'''');
                else
                    columnData(curCol).size = size;
                end
            else
                columnData(curCol).type = tmpStr;
                columnData(curCol).size = [];
            end
        end
    end
end

if(closeDB)
    mrdDisconnect(db);
end