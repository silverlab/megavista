function scanStruct=db_makeReadme(subject,scanDate,fileName)
% function scanStruct=db_makeReadme(subject,scanDate,fileName)
% PURPOSE: Writes out a readme file and readme.mat data structure that can
% be used by mrInitRet
% AUTHOR: Wade
% NOTES: Should use Bob's mrdata stuff for better / more functionality - this is really just a toy script
if (~exist('fileName','var'))
    fileName='readme_db.txt';
end


[sessionID,sessionInfo]=db_pickSession(subject,scanDate);

scanInfo=db_whatScansInSession(sessionID,0);
nScans=length(scanInfo.id);


fid=fopen(fileName,'wt');
if(fid~=-1)
    fprintf(fid,'Session number: %s',int2str(sessionID));
    
    fprintf(fid,'\r\nReadme file generated %s',datestr(now));
    
    fprintf(fid,'\r\n%s\r\n-------------------------------------\r\n',sessionInfo');
    
    for thisScan=1:nScans
    fprintf(fid,'\r\n%s\r\n-------------------------------------',['ID:',int2str(scanInfo.id(thisScan))]);
    fprintf(fid,'\r\nStim type: %s\r\n',[char(scanInfo.stimulusType(thisScan))]);
    fprintf(fid,'\r\nNotes: %s\r\n',[char(scanInfo.notes(thisScan))]);
    fprintf(fid,'\r\nscanParams: %s\r\n',[char(scanInfo.scanParams(thisScan))]);
    fprintf(fid,'\r\nPfile: %s\r\n',['Pfile #',int2str(scanInfo.Pfile(thisScan))]);
    end

    fclose(fid);
    fprintf('Data written to %s',fileName);
    
else
    error('Could not open file for writing');
end

