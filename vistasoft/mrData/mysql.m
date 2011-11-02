% MYSQL - Interact with a MySQL database server
%
%   If no output arguments are given on the left, then display results.
%   If arguments are given, then return requested data silently.
%
%   mysql( 'open', host, user, password )
%      Open a connection with specified parameters, or defaults if none
%            host:  default is local host. Use colon for port number
%            user:  default is Unix login name.
%        password:  default says connect without password.
%
%       Examples: mysql('open','arkiv')       %  connect on port 0
%                 mysql('open','arkiv:2215')
%
%   mysql('close')
%      Close the current connection
%
%   mysql('use',db)  or   mysql('use db')
%      Set the current database to db   Example:  mysql('use cme')
%
%   mysql('status')
%      Display information about the connection and the server.
%      Return    0     if connection is open and functioning
%             nonzero  if something is not correct (see code for details)
%
%   mysql( query )
%      Send the given query or command to the MySQL server
%
%      With no output arguments on the left side, display the result
%      If arguments are given on the left, then each argument
%          is set to the column of the returned query.
%      Dates and times are converted to Matlab format: dates are
%          serial day number, and times are fraction of day.
%      String variables are returned as cell arrays.
%
%      Example:
%      [ t, p ] = mysql('select time,price,askbid from cme.sp
%                  where date="1997-04-30" and expir like "1997-06-%"');
%         (but be sure to put quoted text all on one input line)
%      Returns time and price for trades on the June 1997 contract
%      that occured on April 30, 1997.
%
%   struct = mysql( query , '' )
%      Sends the query to the MySQL server and stores the result in a 
%          struct array with corresponding fields names. All other
%          features are just the same as  for the previous syntax.
%
%      Example:
%             a = mysql('SELECT id,name FROM test','');
%      The result is:
%               a(1).id = 1     a(1).name = 'Bob'
%               a(2).id = 2     a(2).name = 'Marley'
%               . . .           . . .
