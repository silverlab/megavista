function [paths] = findFilePattern(pattern,startDir,varargin);
% [paths] = findFilePattern(pattern,startDir,[options]);
%
% (Very slowly) Finds files/directories matching a particular string, 
% searching recursively under the startDir (the current directory if omitted).
%
% This is similar to doing `find [startDir] -iname [*pattern*]`
% in unix. Note, however, that this is not sophisticated enough to use
% the special search characters, like * or []; it just does a findstr
% on the file name. So, pattern should just be a string somewhere in the
% file name. (I'll update this if I learn a reasonably way to do it.)
%
% Returns a cell containing the names of files and directories containing
% the desired string. By default, these 
% names are paths relative to the startDir. Can also be made to return
% the full path or just the file name, using the 'fullpath' and 
% 'filename' flags, respectively.
%
% Other options
%   'incldirs': include directory names as well as files
%   'suffix': only accept when the pattern is at the end of the
%             name. equivalent to using a pattern "*[pattern]". 
%             useful for searching by file extensions.
%   'prefix': only accept when the pattern is at the start of the
%             name. equivalent to using a pattern "[pattern]*". 
%   'exact':  only accept exact matches. Equivalent to setting both
%             'suffix' and 'prefix' options.
%   'case':   make search case-sensitive. By default, it isn't.
%
% NOTE: This whole thing is very slow ... I haven't made it
% very speed-optimized.
%
% 03/23/04 ras.
% 04/24/04 ras: added case insensitivity, case-sesntivity option
if ~exist('startDir','var') | isempty(startDir)
    startDir = pwd;
end

% params / defaults
pathOption = 1;
inclDirs = 0;
suffixFlag = 0;
prefixFlag = 0;
caseSensitive = 0;

% parse the options
varargin = unNestCell(varargin);
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
            case 'fullpath',
                pathOption = 2;
            case 'filename',
                pathOption = 3;
            case 'incldirs',
                inclDirs = 1;
            case 'suffix',
                suffixFlag = 1;
            case 'prefix',
                prefixFlag = 1;
            case 'exact',
                suffixFlag = 1;
                prefixFlag = 1;
            case 'case',
                caseSensitive = 1;
        end
    end
end

paths = {};

w = dir(startDir);

% recursively search the subpaths
for i = 1:length(w)
    if w(i).isdir & length(w(i).name) > 2 % omit . and ..
        subDir = fullfile(startDir,w(i).name);
        paths = [paths findFilePattern(pattern,subDir,varargin)];
    end
end

% if case-insensitive, use lowercase for pattern
if caseSensitive==0
    pattern = lower(pattern);
    tmpw = w;
    for i = 1:length(w)
        w(i).name = lower(w(i).name);
    end
end

% find files/dirs within the current start dir
A = ones(length(w),1);
for i = 1:length(w)
	if isempty(findstr(pattern,w(i).name)) | length(w(i).name) < 3 % omit . and ..
		A(i) = 0;	% entry does not contain pattern        
    else
        if suffixFlag==1 
            % don't accept if any further characters follow pattern
            pos = findstr(pattern,w(i).name);
            if length(w(i).name) > pos + length(pattern)
                A(i) = 0;
            end
        end
        
        if prefixFlag==1
            % don't accept if any characters precede pattern
            pos = findstr(pattern,w(i).name);
            if pos > 1
                A(i) = 0;
            end    
        end
    end
        
    if inclDirs==0 & w(i).isdir
        A(i) = 0;   % exclude directories in the final set of paths
	end
end

% restore case of paths, if case-insensitive search
if caseSensitive==0
    w = tmpw;
end

outdir = w(find(A));

% return different strings depending on path option
switch pathOption
    case 1, % relative path to startDir
        fnames = grabfields(outdir,'name');
        for i = 1:length(fnames)
            fnames{i} = fullfile(startDir,fnames{i});
        end
		paths = [paths fnames];        
    case 2, % full path
        fnames = grabfields(outdir,'name');
        for i = 1:length(fnames)
            fnames{i} = fullfile(pwd,startDir,fnames{i});
        end
		paths = [paths fnames];        
    case 3, % just the file name
		paths = [paths grabfields(outdir,'name')];
end


return