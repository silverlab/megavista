function db = mrdConnect
%
% function db = mrdConnect
%
% MrData function to connect to the default database.
%
% RETURNS: the database connection (a java object).
%
% 2001.01.23 Bob Dougherty <bob@white.stanford.edu>
%

persistent dbUsername;
persistent dbUserId;
persistent dbUser;
persistent dbPasswd;
persistent dbName;
persistent dbServer;
if(isempty(dbUser)) dbUser='vista'; end
if(isempty(dbServer)) dbServer='darwin.ski.org'; end
if(isempty(dbName)) dbName='mrDataDB'; end
if(isempty(dbPasswd)) dbPasswd='test'; end
if(isempty(dbUserId)) dbUserId=0; end
if(isempty(dbUsername)) dbUsername='wade'; end

abort = 0;
db = [];
tryNum = 0;
dlgTitle = 'Connect to mrData database...';
while(isempty(db) & ~abort)
    if(isempty(dbServer) | isempty(dbName) | isempty(dbUser) | isempty(dbPasswd) | isempty(dbUsername))
        answer = inputdlg({'Server:','DB name:','DB user:','DB Password:','Your Username:'},dlgTitle,1,...
            {dbServer,dbName,dbUser,dbPasswd,dbUsername});
        if max(size(answer))>0
            dbServer = answer{1};
            dbName = answer{2};
            dbUser = answer{3};
            dbPasswd = answer{4};
            dbUsername = answer{5};
        else
            abort = 1;
            disp('Database connect cancelled.');
        end
    end

    try
        r1=mysql('open', dbServer, dbUser, dbPasswd);
        mysql('use', dbName);
        db = 1;
    catch
        
        disp(lasterr);
        dispErr;
    end
    if(isempty(db))
        tryNum = tryNum+1;
        dbPasswd = '';
        disp('*****************************************************');
        disp('CONNECTION FAILED!');
        disp('Perhaps you got the wrong server, dbName, username or password?');
        disp('*****************************************************');
        dlgTitle = ['RETRY #' num2str(tryNum) ': connect to mrData database...'];
    end
end

% OK- we got access to database. Now verify username.
% *** NOTE: we can also add password checking here.
userId = mysql(['SELECT id FROM users WHERE username="',dbUsername,'"']);
if(max(size(dbUserId))>1) % More than one user found
  dbUserId = dbUserId(1);
  myWarnDlg('More than one user with this username found. Using the first one.');
  return;
elseif(min(size(userId))==0) % No such user in a database
  Answer = questdlg(['No users named ' dbUsername ' found in the database. Do you want to create a new record?'],...
      'New record','Cancel','OK','Cancel');
  if(strcomp(Answer,'Cancel'))
    dbUserId = 0;
    myWarnDlg('Proceeding as a GUEST user- db functions may not work properly.');
  else
    done = 0;
    while(~done)
      answer=inputdlg({'First name:','Last name:','Organization:','E-mail:','Username:'}...
        ,'Create a new user',1,{'','','',[dbUsername '@'],dbUsername});
      if(isempty(answer)) % Cancel button
        dbUserId = 0;
        myWarnDlg('Proceeding as a GUEST user- db functions may not work properly.');
        return;
      end
      if(~isempty(mysql(['SELECT id FROM users WHERE email="',answer{4},'"'])))
        myWarnDlg('This e-mail is already in the database. Try again.');
      elseif(~isempty(mysql(['SELECT id FROM users WHERE username="',answer{5},'"'])))
        myWarnDlg('This username is already in the database. Try again.');
      else
        done = 1;
      end;
    end
    mysql(['INSERT INTO users (firstName,lastName,organization,email,username,notes) VALUES("',...
      answer{1},'","',answer{2},'","',answer{3},'","',answer{4},'","',answer{5},...
      '","created via matlab (' datestr(now,31) ')")']);
    disp(['New user ',answer{5},' has been created.']);
  end
  return;
else % Normal situation - one user found
  return;
end
return

function dispErr
    disp('*');
    disp('*********************************************************');
    disp('ERROR CONNECTING TO DATABASE');
    disp('Maybe the mysql mex file isn''t in your path?');
    disp('*********************************************************');
    disp('*');
return