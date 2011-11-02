function db = mrdDisconnect(db)
%
% function db = mrdDisconnect([db])
%
% MrData function to close to the connection.
%
%
% 2003.08.01 Bob Dougherty <bob@white.stanford.edu>
%

mysql('close');

return