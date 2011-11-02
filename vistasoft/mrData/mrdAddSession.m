function mrdAddSession(mrSessionPath)
% 
%  mrdAddSession(mrSessionPath)
% 
% add a session to mrData database. If specified, 
% mrSessionPath must be a full path name.
%
% Here's what we do:
% 1) Build a 'Session' entry (manual)
% 2) try to build all the 'scan' entries automatically
% 3) automatically add all the important data files to dataFiles
%
%   IN PROGRESS.
%
% Here's what still needs to work:
%   * Updating existing sessions instead of overwriting them
%   * Speeding up search for certain files considerably (calls
%     to 'findFilePattern' in the code are very slow; this function
%     was a quickly-written hack);
%
%
%
% HISTORY
% 
% sometime in 2001: RFD (bob@white.stanford.edu) wrote it.
% 2001.02.22: RFD dusted it off and updated for mrLoadRet3.
% 2004.03.16: ras, updated considerably, grabs loads of information and
% uploads it; still debugging. See also 'readReadme' to get info from a
% readme file.
if(~exist('mrSessionPath', 'var'))
    mrSessionPath = fullfile(pwd, 'mrSESSION.mat');
end

if ~exist(mrSessionPath,'file')
    error('Sorry, you need a valid mrSESSION.mat file.');
end

homeDir = fileparts(mrSessionPath);
load(mrSessionPath);
d = dir(homeDir); 

% GET THE SUBJECT ID
found = mrdSearch(['%',mrSESSION.subject,'%'],'subjects');
% mrdSearch returns a 3d cell array.  It's table X row X field.  Since we have
% only 1 table, we only care about found{1}.
if(size(found,1)==1)
    subID = found{1};
    disp(['"',mrSESSION.subject,'" found in db: id=',found{1},...
            '; name=',found{2},' ',found{3},'.']);
else
    % a nod to back-compatibility: sometimes initials are used.
    % check in a lookup table if we can't figure out the full name
    fullName = mrdUserInitials(mrSESSION.subject);
    if ~isempty(fullName)
        found = mrdSearch(['%',fullName,'%'],'subjects');
    end
    
    if (size(found,1)==1)
        subID = found{1};
        disp(['"',fullName,'" found in db: id=',found{1},...
                '; name=',found{2},' ',found{3},'.']);
    else
        fprintf('\n\n ***** Subject %s did not produce a unique match. Select manually... *****\n\n',mrSESSION.subject);
        subID = mrdSelectGUI('subjects');
    end
end

% GET THE STUDY ID
% fileparts will parse the path for us.  We do it twice to get the name of the
% grandparent of homedir (which is often something meaningfully related to the study name).
[p,studyNameGuess] = fileparts(fileparts(homeDir));
found = mrdSearch(['%',studyNameGuess,'%'],'studies','title');
if(size(found,1)==1)
    studyID = found{1};
    studyCode = found{2};
else
    fprintf('\n\n ***** Study %s did not produce a unique match. Select manually... *****\n\n',studyNameGuess);
    studyID = mrdSelectGUI('studies');
    found = mrdSearch(num2str(studyID),'studies','id');
    studyCode = found{2};
end

% % FIND FILES AND INSERT INTO DATAFILES (huh? -ras)
% for(i=[1:length(d)])
%     if(~d(i).isdir)
%         disp([d(i).name,'  ',d(i).date,'  ',num2str(d(i).bytes)]);
%     else
%         disp([d(i).name,' is a directory.']);
%     end
% end

% read the Readme.txt file
fid = fopen(fullfile(homeDir,'Readme.txt'),'r');
if fid > 0
    readMeText = fscanf(fid,'%c');
    fclose(fid);
    
    readMeText = rmQuotes(readMeText);
end
% also good to load it in a struct format, to get specific fields 
% like comments for the session:
info = readReadme; 

% GET THE OPERATOR ID %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
found = mrdSearch(['%',info.operator,'%'],'users');
% mrdSearch returns a 3d cell array.  It's table X row X field.  Since we have
% only 1 table, we only care about found{1}.
if(size(found,1)==1)
    opID = found{1};
    disp(['"',info.operator,'" found in db: id=',found{1},...
            '; name=',found{2},' ',found{3},'.']);
else
    % a nod to back-compatibility: sometimes initials are used.
    % check in a lookup table if we can't figure out the full name
    fullName = mrdUserInitials(info.operator);
    if ~isempty(fullName)
        found = mrdSearch(['%',fullName,'%'],'users');
    end
    
    if (size(found,1)==1)
        opID = found{1};
        disp(['"',fullName,'" found in db: id=',found{1},...
                '; name=',found{2},' ',found{3},'.']);
    else
        fprintf('\n\n ***** Operator %s did not produce a unique match. Select manually... *****\n\n',info.operator);
        opID = mrdSelectGUI('users');
    end
end

% GET THE DISPLAY ID %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (unfortunately, this information doesn't seem to be saved anywhere in the
% current mrLoadRet setup. mrInitRet should be modified to get this
% information, and parallel changes may need to be made in readReadme. 'Till
% then, we'll just have to do it graphically:)
fprintf('\n\n ***** Please Select the Display ***** \n\n');
dispID = mrdSelectGUI('displays');
tic

% GET ANY VOLUME ALIGNMENT INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for a bestrotvol.mat file 
% (will also update to read BV files)
alignment = '';
if exist('bestrotvol.mat','file')
    align = load('bestrotvol');
    alignment = printStruct(align);
end
% also check for BV .trf alignment files
trfFiles = findFilePattern('.trf',pwd,'suffix');
for i = 1:length(trfFiles)
    fid = fopen(trfFiles{i},'r');
    txt = fscanf(fid,'%c');
    fclose(fid);
    alignment = sprintf('%s\n\n%s:\n%c',alignment,trfFiles{i},txt);
end
if exist('vANATOMYPATH','var')
    alignment = sprintf('%s\n\nvAnat: %s',alignment,vANATOMYPATH);
end

% GET ANY ESTIMATED MOTION INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These are files with summaries of the estimated motion during
% the scan
motion = '';
motFiles = findFilePattern('.mcdat'); % afni/fs-fast format
for i = 1:length(motFiles)
    fid = fopen(motFiles{i},'r');
    txt = fscanf(fid,'%c');
    fclose(fid);
    motion = sprintf('%s\n\n%s:\n%c',motion,motFiles{i},txt);
end


% GET STIMULUS INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for a 'stim' directory in the session, containing stimulus
% files for this scan:
toc
stim = mrdGetStimFiles(homeDir);

% ------------- create the session entry ------------- 
fields = {...
    'id';...
    'sessionCode';...
    'start';...
    'end';...
    'examNumber';...
    'primaryStudyID';...
    'subjectID';...
    'operatorID';...
    'displayID';...
    'readme';...
    'notes';...
    'fundedBy';...
    'whoReserved';...
    'scanner';...
    'dataSubDirectory';...
    'matlabCode';...
    'parFiles';...
    'prtFiles';...
    'scriptFiles';...
    'alignment';...
    'estMotion';...
};

% check if a session matching this one already exists;
% if it does, get the id, so we update rather than add a 
% second copy of the record:
sessionID = [];

sessCode = [studyCode '_' mrSESSION.sessionCode];
if isfield(mrSESSION.functionals(1),'time')
    tStart = mrSESSION.functionals(1).time; % just an estimate, based on 1st scan
	tEnd = mrSESSION.functionals(end).time; % just an estimate, based on last scan 
	date = mrSESSION.functionals(1).date;
	mo = date(1:2);
	dt = date(4:5);
	yr = date(7:8);
	tStart = sprintf('20%s-%s-%s %s:00',yr,mo,dt,tStart); % not y2.1k-compatible
	tEnd = sprintf('20%s-%s-%s %s:00',yr,mo,dt,tEnd)
else
    tStart = [];
    tEnd = [];
end
sessNotes = rmQuotes(info.description);
sessNotes = sprintf('%s \n %s',sessNotes,rmQuotes(info.comments));
switch info.magnet % Lucas-specific -- if field structure changed, change this.
    case '3 T'     % (The field is a radio-button design, takes ints (I think))
        scanner = 2;
    case '1.5 T'
        scanner = 1;
    otherwise
        scanner = 0;
end
dataSubDir = homeDir;
dataSubDir(dataSubDir=='\') = '/'; % backslashes get edited out

values = {sessionID,sessCode,tStart,tEnd,mrSESSION.examNum,...
          studyID,subID,opID,dispID,readMeText,...
          sessNotes,[],[],scanner,dataSubDir,...
          stim.matlabCode,stim.parFiles,stim.prtFiles,...
          stim.scriptFiles,alignment,motion}; 
          
fprintf('\n\n%% ------------------------- UPLOADING SESSION %s ------------------------- %%\n\n\',sessCode);

  
[numUpdated,idStruct] = mrdInsert('sessions', values, fields);

if numUpdated == 0
    errmsg = sprintf('Update failed. Session %s',mrSESSION.sessionCode);
    error(errmsg);
else
    fname = 'last_insert_id()';
    sessionID = idStruct.(fname);
    fprintf('Successfully added sessions entry (id: %i) with %i rows.\n',sessionID,numUpdated);
end

fprintf('\n\n%% ------------------------- Done uploading session. ------------------------- %%\n');


% ------------- for each scan, create a scans entry ------------- 
fields = {...
    'id';...
    'scanCode';...
    'scanNumber';...
    'stimulusID';...
    'stimulusType';...
    'notes';...
    'scanParams';...
    'sessionID';...
    'primaryStudyID';...
    'scanType';...
    'Pfile';...
    'behavData';...
    'parfile';...
    'script';...
    'matlabCode';...
};

nScans = length(mrSESSION.functionals);

fprintf('\n\n%% ------------------------- UPLOADING SCANS ------------------------- %%\n\n\');

for s = 1:nScans
    fprintf('\n%% ---------- SCAN %i:\n',s);
    
    scanCode = sprintf('%s-%02.0f',mrSESSION.sessionCode,s);
    stimulusID = [];
    stimulusType = [];
    notes = dataTYPES(1).scanParams(s).annotation; 
    notes = sprintf('%s \n Session comments: %s',notes,rmQuotes(info.comments));
    scanParams = getScanParams(dataTYPES,s);
    scanType = [];
    PfileNum = mrSESSION.functionals(s).PfileName(2:8);
    
    behavData = getScanBehavData(s);
    parfiles = getScanTextFiles(s,'parfile');
    scripts = getScanTextFiles(s,'script');
    matlabCode = getScanTextFiles(s,'matlabCode');
    
    
    values = {[],scanCode,s,stimulusID,stimulusType,notes,...
              scanParams,sessionID,studyID,scanType,...
              PfileNum,'behavData',parfiles,scripts,...
              matlabCode};
    
    [numUpdated,idStruct] = mrdInsert('scans', values, fields);
    
    if numUpdated == 0
        errmsg = sprintf('Update failed. Session %s, scan %i.',mrSESSION.sessionCode,s);
        error(errmsg);
    else
        fname = 'last_insert_id()';
        scanID = idStruct.(fname);
        fprintf('Successfully added scans entry (id: %i) with %i rows.\n',scanID,numUpdated);
    end
end

fprintf('\n\n%% ------------------------- Done uploading scans. ------------------------- %%\n');

return




function txt = getScanParams(dataTYPES,scan);
% given a mrLoadRet dataTYPES struct, produces a char vector with the
% scanParams, blockedAnalysisParams, and eventAnalysisParams fields printed
% out, for the db. 
sp = printStruct(dataTYPES(1).scanParams(scan));
bap = printStruct(dataTYPES(1).blockedAnalysisParams(scan));
eap = printStruct(dataTYPES(1).eventAnalysisParams(scan));
txt = sprintf('Scan Params:\n%s \n Blocked Analysis Params:\n %s \nEvent Analysis Params:\n %s',sp,bap,eap);
return



function data = getScanBehavData(scan);
% Gets any specified behavioral data for a 
% scan, for uploading (as a blob) to the db.
% The field in dataTYPES is a string specifying
% the path; many files may be specified, separated
% by ' AND '.
global dataTYPES;
data = [];
if isfield(dataTYPES(1).scanParams(scan),'behavData') & ...
    ~isempty(dataTYPES(1).scanParams(scan).behavData)
    pth = dataTYPES(1).scanParams(scan).behavData;
    manyFiles = findstr(' AND ',pth);
    if ~isempty(manyFiles)
        % remove the ' AND ' strings and get file paths
        bounds = [-4 manyFiles length(pth)];
        for i = 1:length(bounds)-1
            files{i} = pth(bounds(i)+5:bounds(i+1));
        end
    else
        files = {pth};
    end

    % load any files that are found
    for i = 1:length(files)
        if exist(files{i},'file')
            fieldName = ['file' num2str(i)];
            data.(fieldName) = load(pth);
            data.(fieldName).filePath = files{i};
        else
            fprintf('File %s not loaded because not found...\n',files{i});
        end
    end

end
return




function txt = getScanTextFiles(scan,field);
% Loads/concatenates text files specified by a 
% field in dataTYPES.scanParams. Fields may include
% things like 'matlabCode' or 'parfile', and is a
% string specifying the path or paths of the text file/s; 
% many files may be specified, separated by ' AND '.
global dataTYPES;
txt = '';
if isfield(dataTYPES(1).scanParams(scan),field) & ...
    ~isempty(dataTYPES(1).scanParams(scan).(field))
    pth = dataTYPES(1).scanParams(scan).(field);
    manyFiles = findstr(' AND ',pth);
    if ~isempty(manyFiles)
        % remove the ' AND ' strings and get file paths
        bounds = [-4 manyFiles length(pth)];
        for i = 1:length(bounds)-1
            files{i} = pth(bounds(i)+5:bounds(i+1));
        end
    else
        files = {pth};
    end

    % load any files that are found
    for i = 1:length(files)
        if exist(files{i},'file')
            txt = sprintf('%s%s: \n',txt,files{i});
            fid = fopen(files{i},'r');
            newtxt = fscanf(fid,'%c');
            fclose(fid);
            txt = sprintf('%s%s\n\n\n',txt,newtxt);
        else
            fprintf('File %s not loaded because not found...\n',files{i});
        end
    end

end
return


function txt = printStruct(structIn);
% given a struct, produces a char vector
% that prints out the contents of the struct:
% [field name]: [field values]
% for all fields in the struct, similar to what you'd 
% see if you typed the name of the struct in the 
% command window.
txt = '';
names = fieldnames(structIn);
for i = 1:length(names)

    if ischar(structIn.(names{i}))
        val = structIn.(names{i});
    elseif isnumeric(structIn.(names{i}))
        mat = structIn.(names{i});
        if size(mat,1) > 1 & size(mat,2) > 1
           val = num2str(mat)'; % very crude way to print matrices
        else
           val = num2str(structIn.(names{i}));
        end
    elseif isstruct(structIn.(names{i}))
        val = '(struct)';
    else
        val = '(something not a char, number, or struct)';
    end
    
    txt = sprintf('%s \n %s:\t %s',txt,names{i},val);
end
return




function txt = rmQuotes(txt);
% To prevent security vulnerabilities on the web page,
% it's a wise precaution to add a backslash before single
% quotes in text (or else some mySQL code could get executed from e.g.
% a PHP script). Remember to update in case other special characters
% are found to be potentially problematic.

% rm single quotes
quotelocs = findstr('''',txt);
quotelocs = quotelocs(txt(quotelocs-1)~='\');
while ~isempty(quotelocs)
    j = quotelocs(1);
    txt = [txt(1:j-1) '\' txt(j:end)];
	quotelocs = findstr('''',txt);
	quotelocs = quotelocs(txt(quotelocs-1)~='\');
end

% rm double quotes
quotelocs = findstr('"',txt);
quotelocs = quotelocs(txt(quotelocs-1)~='\');
while ~isempty(quotelocs)
    j = quotelocs(1);
    txt = [txt(1:j-1) '\' txt(j:end)];
	quotelocs = findstr('"',txt);
	quotelocs = quotelocs(txt(quotelocs-1)~='\');
end

return