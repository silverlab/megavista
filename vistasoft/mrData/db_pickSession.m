function [sessionID,sessionInfo]=db_pickScanSession(subName,scanDate,verbose)
% scanStruct=db_pickScanSession(subName,scanDate,verbose)
% PURPOSE: Returns a sessionID for a particular scan subject and date. 
% If more than one scan session exists for the particular subject / data
% combination in the db, the used is prompted to choose the correct one.
%
% NOTES: 
% 'verbose' is on by default. Set to 0 for a quiet time.
% Does not require a mrSESSION
%
% HISTORY:
% 2003.08 Wade wrote it.
% 2003.09.09 RFD (bob@white.stanford.edu) modified to use mrData functions.
%

if (~exist('verbose','var'))
    verbose=1;
end

db = mrdConnect;
subID = mrdQuery(['select id from subjects where lastname = "',lower(subName),'"'], db);
if (length(subID)==0)
    error('No subjects with that last name were found');
end
if(length(subID)~=1)
    error('More than one subject with that last name found - cannot continue');
end


% Get all the scans for that subject
%
% We get everything at once by joing the sessions and study table. Note,
% however, a limitation of mysql.mex- it doesn't prepend the table name to
% the column name. Thus, if we happened to want two columns with the same
% name from the two tables (eg. 'id'), then we'd be out of luck. This limit
% also makes the code harder to read, since it isn't obvious from which
% table a particular column has come.
%
% In theory, we do even eliminate the separate subject query by joining
% that table in here alos. But, by doing that one separately, we can
% provide more informative errors (eg. if the subject search fails).
q = ['SELECT sessions.id,sessions.notes,sessions.start,sessions.sessionCode,studies.studyCode,studies.title ', ...
     'FROM sessions,studies ', ...
     'WHERE studies.id=sessions.primaryStudyId AND sessions.subjectID=',int2str(subID.id)];

sessions = mrdQuery(q, db);

startDate = cellstr(datestr([sessions.start],2));
goodSessions = find(strcmp(startDate,scanDate));
numMatch = length(goodSessions);

switch numMatch
    case 0
        warning('No sessions found for the requested date and subject');
    case 1
        sessionInfo = [int2str(sessions(goodSessions).id),...
                ' :: Code-',char(sessions(goodSessions).studyCode), ...
                ' :: Title-',char(sessions(goodSessions).title), ...
                ' :: Start time (approx) ',datestr(sessions(goodSessions).start, 13)];
        sessionID = sessions(goodSessions).id;
    otherwise
        % Here if we had two or more sessions on that date:
        menuStr = 'Select correct session';
        for(ii=1:length(goodSessions))
            sIndex = goodSessions(ii);
            sessionInfo{ii} = [int2str(sessions(sIndex).id), ...
                    ' :: Session Code-',char(sessions(sIndex).sessionCode), ...
                    ' :: Study Code-',char(sessions(sIndex).studyCode), ...
                    ' :: Title-',char(sessions(sIndex).title), ...
                    ' :: Start time (approx) ',datestr(sessions(sIndex).start,13)];
        end
        correctID = menu(menuStr,sessionInfo);
        sessionInfo = sessionInfo{correctID};
        sessionID = sessions(goodSessions(correctID)).id;
end
mrdDisconnect(db);
return;

