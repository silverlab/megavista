function scanStruct=db_whatScansInSession(sessionID,verbose)
% scanStruct=db_whatScansInSession(sessionID,verbose)
% PURPOSE: Returns a list of all scans for a single session (see also db_whatSessionSub)
% AUTHOR: Wade
% NOTES: Should use Bob's mrdata stuff for better / more functionality - this is really just a toy script
% to learn mysql interfacing...
% 'verbose' is on by default. Set to 0 for a quiet time.
% e.g. outStruct=db_whatScansInSession(86,0);
% See also db_whatSessionsSub

if (~exist('verbose','var'))
    verbose=1;
end 

stat=mysql('status');
if (stat) 
    mysql('open','darwin','vista','test');
end

mysql('use','mrDataDB');

stat=mysql('status');
if (stat)
    error('Cannot access database');
end

[id,stimulusType,notes,scanParams,Pfile]=mysql(['select id,stimulusType,notes,scanParams,Pfile from scans where sessionID =',int2str(sessionID)]);
if (length(sessionID)==0)
    error('No subjects with that last name were found');
end
if(length(sessionID)~=1)
    error('More than one subject with that last name found - cannot continue');
end

scanStruct.id=id;
scanStruct.stimulusType=stimulusType;
scanStruct.notes=notes;
scanStruct.scanParams=scanParams;
scanStruct.Pfile=Pfile;

% Also get the plaintext readout of the scan IDs
nScans=length(id);
[y,i]=sort(id); % Sort by id

for thisScanIndex=1:nScans
    thisScan=i(thisScanIndex);
    if (verbose)
        
        fprintf('\nScanID #%d\t: Type: %s\t\t: notes: %s\t: Params: %s\t: Pfile %d',id(thisScan),num2str(stimulusType(thisScan)),notes{thisScan},scanParams{thisScan},Pfile(thisScan));
    end
    
end


mysql('close');

