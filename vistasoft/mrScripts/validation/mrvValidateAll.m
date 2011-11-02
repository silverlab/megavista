function logfile = mrvValidateAll(logfile)
% Validate all validation functions found in vistasoft validation
% directory, creating a log file detailing validation resutls.
%
%  logfile = mrvValidateAll([logfile])
%
% Examples: 
%   logfile = mrvValidateAll
%   logfile = mrvValidateAll('~/mylogfile.txt');
%   edit(mrvValideAll)
%   edit(mrvValidateAll('~/mylogfile.txt'));
%
% Copyright Stanford team, mrVista, 2011

curdir = pwd;

%% Check whether vistadata is on the path
if ~exist('mrvDataRootPath', 'file'),
    error('The vistdata repository is not on the matlab path. Please add this repository to the path and then rerun mrvValidateAll.') 
end

%% Output file
if notDefined('logfile')
    logfile = fullfile(pwd, sprintf('mrvValidateLog_%s.txt', ...
        datestr(now, 'yyyy_mm_dd_HH-MM-SS')));
end

fid = fopen(logfile,'w+');



%% Get a list of all validate functions on the mrVista path
pth = fileparts(which('mrvValidate'));
d = dir(fullfile(pth, 'v_*.m'));

%% Write some headers at the top of the logfile
fprintf(fid, 'mrvValidateAll called %s\n', datestr(now, 'yyyy_mm_dd_HH-MM-SS'));
fprintf(fid, 'Functions tested:\n');
for ii = 1:numel(d)
    fprintf(fid, '\t%s\n', d(ii).name);
end

%% Validate

% Loop throught the validation functions, testing each one and writing the
% results to the log file as we go.
for ii = 1:length(d)
    
    tStart = tic;
    % <callingFunction> is the name of the validation function. We lop of
    % the '.m' because Matlab function calls do not accept '.m' in the
    % call.
    callingFunction = d(ii).name(1:end-2);
    
    % We will run the calling function in a try-catch statement in order to
    % catch and record and errors, should the callingFunction fail to
    % return a value. <callingFunctionRan> is a boolean indicating whether
    % the callingFunction ran successfully or not (irrespective of whether
    % the calculations are accurate).
    try
        % <val> is the output of the calling function. It should be a
        % structured array.
        val = eval(callingFunction);
        
        % <stored> is the stored value from <callingFunction>
        dataFile        = [callingFunction(3:end) '.mat']; % lop off the 's_'
        vFile = fullfile(mrvDataRootPath,'validate', dataFile);
        stored = load(vFile);
    
        % Compare val and stored.
        [OK, str] = mrvValidate(stored,val,callingFunction);

        callingFunctionRan = true;
        
    catch ME
            callingFunctionRan = false;
    end
    
    tElapsed = toc(tStart);
       
    fprintf(fid, '\n---------------------------\n');
    
    if callingFunctionRan
        % then print out the str returned by mrvValidate
        fprintf(fid, '%s validation: %d\n', callingFunction, OK);
        if ischar(str)
            fprintf(fid, '\t%s\n', str);
        
        else

            for s = 1:length(str)
                % Some strings have multiple lines.  These are stored in
                % the rows.  We have to print one row at a time.
                [r,c] = size(str{s});
                for rr = 1:r
                    fprintf(fid, '\t%s\n', str{s}(rr,:));
                end
            end
        end
    else % callingfunction returned with an error
        fprintf(fid, '%s did not run successfully. The following error was produced:\n', callingFunction);
        fprintf(fid, '\t%s\n', ME.identifier);
        fprintf(fid, '\t%s\n', ME.message);     
        for jj = 1:length(ME.stack)
            fprintf(fid, '\t\tfile: %s\n',   ME.stack(jj).file);
            fprintf(fid, '\t\tname: %s\n',   ME.stack(jj).name);
            fprintf(fid, '\t\tline: %d\n\n', ME.stack(jj).line);
        end
    end
    
    % report the calculation time for each validation function
    fprintf(fid, '\tTime elapsed: %f seconds.\n', tElapsed);

end

%% Get and write out computing environment data
env = mrvGetEvironment();
f = fieldnames(env);

fprintf(fid, '-----------------------------------------\n');
fprintf(fid, 'Computing envionment for mrVista validation:\n');

% The computing environment is specified in the structured array <env>. We
% begin by looping through the fields of <env>, and writing each field into
% the log file.
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
    
    % clean the mrVista workspace
    mrvCleanWorkspace;
end
fprintf(fid, '----------------------------------\n');


fclose(fid);

fprintf('Log file written: %s\n', logfile);

cd(curdir)
