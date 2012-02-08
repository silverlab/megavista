%% Get a list of filenames in a directory that match a given regular expression
%
%   Input:
%       datadir: directory that contains data files
%       regex: regular expression to match against file names
%       preprendDataDir: whether to prepend datadir to file names in output
%
%   Output:
%       filenames: a cell array of file names that match the regular
%         expression
%
function fileNames = get_filenames(datadir, regex, prependDataDir)

    if nargin < 3
        prependDataDir = 0;
    end

    dlist = dir(datadir);

    fileCount = 0;
    fileNames = cell(1, 1);
    
    %first gather up the stim and response files
    for k = 1:length(dlist)
        fname = dlist(k).name;
            
        %match files
        [mstr] = regexp(fname, regex, 'match');
        if ~isempty(mstr)
            fileCount = fileCount + 1;
            if prependDataDir
                fname = fullfile(datadir, fname);
            end
            fileNames{fileCount} = fname;
        end            
    end
    
    if fileCount == 0
        fileNames = -1;
    end