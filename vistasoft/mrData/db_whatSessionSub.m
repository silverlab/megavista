function scanStruct=db_whatSessionsSub(subName,verbose)
% scanStruct=db_whatSessionsSub(subName,verbose)
% PURPOSE: Returns a list of all sessions for a single subject (last name required) 
% AUTHOR: Wade
% NOTES: Should use Bob's mrdata stuff for better / more functionality - this is really just a toy script
% to learn mysql interfacing...
% 'verbose' is on by default. Set to 0 for a quiet time.
% e.g. outStruct=db_whatSessionsSub('wade',0);
% See also db_whatScansInSession

db=0;

if (~exist('verbose','var'))
    verbose=1;
end


stat=mysql('status');
if (stat)
    %mysql('open','darwin.ski.org','vista','test');
    db=mrdConnect;
end
 

stat=mysql('status');
if (stat)
    error('Cannot access database');
end

subID=mysql(['select id from subjects where lastname = "',lower(subName),'"']);
    
if (length(subID)==0)
    error('No subjects with that last name were found');
end
if(length(subID)~=1)
    error('More than one subject with that last name found - cannot continue');
end


 
[id,studyID,notes,start]=mysql(['select id,primaryStudyID,notes,start from sessions where subjectID =',int2str(subID)]);
scanStruct.id=id;
scanStruct.primaryStudyID=studyID;
scanStruct.notes=notes;
scanStruct.start=start;


nSessions=length(scanStruct.id);
thisStart=[scanStruct(1).start];
for t=1:nSessions
  thisStart(t)=[scanStruct.start(t)];
end
% 

[y,i]=sort(thisStart); 



%keyboard


for thisSessionIndex=1:nSessions
    thisSession=i(thisSessionIndex);

    if (~scanStruct.primaryStudyID(thisSession)) % Check for in invalid study ID
        thisPrimaryName{1}='No study ID found';
    else
        
        thisStudy=int2str(scanStruct.primaryStudyID(thisSession));
        [thisPrimaryName,c]=mrdQuery(['select title from studies where id =',thisStudy],db);
    end
    
    scanStruct.studyType{thisSession}=thisPrimaryName;
    
    if (verbose)
        fprintf('\nSessID #%d\tType: %s\t\tTime: %s',scanStruct.id(thisSession),thisPrimaryName{1},datestr(scanStruct.start(thisSession)));
    end
    
end


mysql('close');

