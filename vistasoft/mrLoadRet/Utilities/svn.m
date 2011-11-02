function svn(varargin)

curdir = pwd;

cd ~/matlab/svn/vistasoft/

if length(varargin) == 1
    arg = varargin{1};
else
    arg = [];
    for ii = 1:length(varargin)
        arg = [arg ' ' varargin{ii}]; %#ok<AGROW>
    end
end

eval(sprintf('!svn %s', arg));

cd(curdir)

