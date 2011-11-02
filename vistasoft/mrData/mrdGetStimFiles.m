function stim = mrdGetStimFiles(homeDir);
% stim = mrdGetStimFiles(homeDir);
%
% mrdGetStimFiles: look for stimulus files in a session directory
%
% This originates from practices in Kalanit's lab and can be changed as
% necessary: our session dirs tend to have 'stim' directories with matlab
% code relevant to that scanning session, and par/prt files which specify
% the stimulus sequence used for different scans. Check if any of this
% exists, and if it does, load it and format it for uploading to the db.
%
% The returned 'stim' struct has the following fields:
%
%   matlabCode: a char vector containing the full text of any m-files in
%   the stim directory, with headers indicating the file name. Includes
%   return characters, so outputting this should accurately reproduce the
%   m-files (except for single quotes, see below).
%
%   mexFiles: a cell list of the .mex files in the stim directory. Currently
%   just a list, until I figure out how to pass and upload binary files.
%
%   parFiles: a char vector containing the contents of any files in the
%   stim/parfiles directory, if it exists. For event-related analyses, 
%   parfiles specify the onset times and conditions (and sometimes names) 
%   of different trials.
%
%   prtFiles: a char vector, similar to parFiles, containing the contents
%   of any files ending in .prt. Prtfiles are like parfiles, but are used
%   by BrainVoyager.
%
%   scriptFiles: yet another form of specifying onset times for event-related 
%   experiments are text script files. Much of Kalanit's lab's code uses this
%   (and I believe eprime mayalso use scripts). There's no standard format for 
%   script files, however. ScriptFiles is also a char containing the
%   contents of any script files found in stim/scripts, if it exists.
%
%   dataFiles: like mexFiles, a cell array listing the .mat files in the
%   stim directory. Will be changed if a way is found to upload binary
%   files to the db. (Update 03/31/04: can upload these binaries, but
%   right now I find that some sessions have so many .mat files, many
%   potentially unrelated to the data, that it would make the whole
%   process take more time and memory than was worth it -- now the
%   scans table in the database accepts behavioral data files for each
%   scan (which can be set with SetupSession) -- this makes more sense).
%
% For security purposes when uploading, a backslash is added before any
% single quotes that appear in any of the loaded text files. I'm told this
% will prevent malicious web scripts from launching mysql code on the db
% web page. (Though it's probably overcaution, it couldn't hurt). See
% rmQuotes, below.
%
%
% 03/16/04 ras.
% 03/23/04 ras: updated to do recursive search by file extension, doesn't
% care about any subdirectories in 'stim', except for 'stim/scripts' for 
% script files.
if ~exist('homeDir','var')
    homeDir = pwd;
end

matlabCode = [];
mexFiles = {};
parFiles = [];
prtFiles = [];
scriptFiles = [];
dataFiles = {}; % check if binary uploads are allowed

tic
stimDir = fullfile(homeDir,'stim');
if exist(stimDir,'dir')
    fprintf('Stim directory found. Scanning for stimulus files...');
    
    
    % find, load, and concatenate all .m files
    % this will go to the 'matlabCode' field in the db.
    mFiles = findFilePattern('.m',stimDir,'suffix');
    for i = 1:length(mFiles)
%         fprintf('Loading %s...\n',mFiles{i});
        
        tittext = sprintf('\n\n\n%%------------------------- %s -------------------------\n',mFiles{i});
        matlabCode = [matlabCode tittext];
        
        fid = fopen(mFiles{i},'r');
        if fid > 0
            code = fscanf(fid,'%c');
            fclose(fid);
            % again, 'inactivate' single quotes from the code
            matlabCode = [matlabCode rmQuotes(code)];
        end
        
    
    end
    
    % find paths of binary files: .mat and .mex
    % (haven't figured out how to upload these yet)
    mexFiles = findFilePattern('.mex',stimDir,'suffix');
    dataFiles = findFilePattern('.mat',stimDir,'suffix');
    
    % kalanit also keeps her behavioral data files in a
    % folder called [homeDir]/behavData, or something like 
    % that, and wants to look for that too:
    check4BehavDir = ~isempty(dir(fullfile(pwd,'behav*')));
    if check4BehavDir==1
        v = dir(fullfile(pwd,'behav*'));
        behavDir = fullfile(homeDir,v(1).name);
        dataFiles = [dataFiles findFilePattern('.mat',behavDir,'suffix')];
    end
    
%     % what the hey -- let's try loading/concatting all the .mat files
%     % (disabled)
%     matlabData = [];
%     if length(dataFiles) > 0
%         fprintf('\nThere are .mat files in the stim dir. Loading and concatenating...');
%         
%         matlabData.paths = dataFiles;
%         
%         for i = 1:length(dataFiles)
%             [ignore fieldName] = fileparts(dataFiles{i});
%             fieldName(fieldName=='-') = '_'; % filter out bad chars
%             matlabData.(fieldName) = load(dataFiles{i});
%         end
%     end
    
    % find, load, concatenate .par files (mrVISTA/fsfast)    
    parList = findFilePattern('.par',stimDir,'suffix');
    for i = 1:length(parList)
%             fprintf('Loading %s...\n',parList{i});
        
        tittext = sprintf('\n\n\n%%------------------------- %s -------------------------\n',parList{i});
        parFiles = [parFiles tittext];
        
        fid = fopen(parList{i},'r');
        if fid > 0
            parfile = fscanf(fid,'%c');
            fclose(fid);
            parFiles = [parFiles rmQuotes(parfile)];                
        end
        
    end

    % find, load, concatenate .prt files (BV)    
    prtList = findFilePattern('.prt',stimDir,'suffix');
    for i = 1:length(prtList)
%             fprintf('Loading %s...\n',prtList{i});
        
        tittext = sprintf('\n\n\n%%------------------------- %s -------------------------\n',prtList{i});
        prtFiles = [prtFiles tittext];
        
        fid = fopen(prtList{i},'r');
        if fid > 0
            prtfile = fscanf(fid,'%c');
            fclose(fid);            
            prtFiles = [prtFiles rmQuotes(prtfile)];
        end
        
    end
    
    % some experiments use text scripts to specify the order of stimuli.
    % this is no particular extension or name convention to these, so we'll
    % assume people keep them in a 'scripts' subdirectory.
    scriptDir = fullfile(stimDir,'scripts');
    if exist(scriptDir,'dir') & length(dir(scriptDir))>2
        scriptList = grabfields(dir(scriptDir),'name');
        for i = 1:length(scriptList)
%             fprintf('Loading %s...\n',scriptList{i});

            tittext = sprintf('\n\n\n%%------------------------- %s -------------------------\n',scriptList{i});
            scriptFiles = [scriptFiles tittext];
            
            scriptpath = fullfile(scriptDir,scriptList{i});
            fid = fopen(scriptpath,'r');
            if fid > 0            
                scriptfile = fscanf(fid,'%c');
                fclose(fid);            
                scriptFiles = [scriptFiles rmQuotes(scriptfile)];            
            end
            
        end
    end
    
end  % if exist(stimDir,'dir')

stim.matlabCode = matlabCode;
% stim.matlabData = matlabData;
stim.mexFiles = mexFiles;
stim.parFiles = parFiles;
stim.prtFiles = prtFiles;
stim.scriptFiles = scriptFiles;
stim.dataFiles = dataFiles; % check if binary uploads are allowed

fprintf('done. %3.2f secs.\n',toc); 

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