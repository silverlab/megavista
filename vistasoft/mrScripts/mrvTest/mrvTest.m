function logfile = mrvTest(logfile)

% Run the vistasoft test-suite. This function wraps matlab_xunit's `runtest` 
%
%
% Paramters 
% ---------
% logfile: string, optional  
%  
% Full path to logfile that will be produced by the test-suite. The file will
% be saved in the pwd, unless another directory is specified in the
% file-name. Defaults to a generic file-name with a time-stamp, generated in
% the pwd. 
%
% Returns
% -------
% logfile: string
% 
% Same as the parameter.  
%
% Copyright Stanford team, mrVista, 2011 
% 


curdir = pwd;

%% Get information regarding the software environmnet
env  = mrvGetEvironment();

test_dir = strcat(fileparts(which('mrvTest.m')),'/tests'); 

% Check whether vistadata is on the path
if ~exist(mrvDataRootPath, 'dir'),
   error('[%s] Need vistdata repository on the path in order to validate data:\nhttp://white.stanford.edu/newlm/index.php/SVN',mfilename)
end


%% Output file if no input provided
if notDefined('logfile')
    logfile = fullfile(pwd, sprintf('mrvTestLog_%s.txt', ...
        datestr(now, 'yyyy_mm_dd_HH-MM-SS')));
end

% Run the tests, return whether or not they passed: 
OK = runtests(test_dir, '-logfile',logfile, '-verbose');

fid = fopen(logfile,'a+');
fprintf(fid, '-----------------------------------------\n');
fprintf(fid, 'Environment information:\n');

f = fieldnames(env);

for ii=1:length(f)
    
    thisfield = env.(f{ii});
    
    % If this field is numeric, we need to convert to a string, or we get
    % a corrupted log file
    if isnumeric(env.(f{ii})), env.(f{ii}) = num2str(env.(f{ii})); end
    
    % If the field is itself a structured array, then we need to loop
    % through the array. For example, <env.matlabVer> is a struct, with one
    % entry for each toolbox on the matlab path.
    if isstruct(thisfield)
        for jj = 1:length(thisfield)
            fprintf(fid, '%s: %s\n', f{ii}, thisfield(jj).Name);
        end
    else
        % If the field is not a struct, write out its name and value.
        fprintf(fid, '%s: %s\n', f{ii}, env.(f{ii}));
    end
end

fclose(fid);

fprintf('Log file written: %s\n', logfile);
