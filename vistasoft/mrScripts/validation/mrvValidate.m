function [OK, str, env] = mrvValidate(stored,val,callingFunction,resave)
% Compare the data fields in two structures for validating mrVista functions
%
%  [OK, str, env] = mrvValidate(stored,val,callingFunction,[resave=0])
%
% If the difference is bigger than 100*eps, we report an error.  
%
% OK:  1 if valid, 0 otherwise
% str: Summary of analysis
% env: Matlab environment when running the test
%
% We (Jon and Brian) analyzed values computed on different platforms
% (Windows and Linux).  There are real differences (on the order of 10^-10
% when computing the means and std dev on different platforms even with
% double precision.  With single precision the differences are much larger.
%
% The differences between single and double precision are large within a
% platform. The basic validate routines (v_*) should always move the
% tSeries or other values to double before calculating a summary statistic.
%
% Examples: 
%       % validate the function v_tSeries4D
%       env = mrvValidate('v_tSeries4D');
%
%       % validate the function v_tSeries4D
%       val = v_tSeries4D;
%       stored = load(fullfile(mrvDataRootPath,'/validate/tSeries4D.mat'));
%       env = mrvValidate('v_tSeries4D',stored,val)
%
% See also mrvValidateAll.m
%
% JW, 6/30/2011: added error tolerance variable <eps>
% FP, 7/22/2011: updated comments.
%
% Copyright Stanford team, mrVista, 2011

%% Check inputs
if notDefined('callingFunction')
    error('Need a function to validate')
end

%% Check whether vistadata is on the path
if ~exist(mrvDataRootPath, 'dir'),
    error('[%s] Need vistdata repository on the path in order to validate data:\nhttp://white.stanford.edu/newlm/index.php/SVN',mfilename) 
end

%% load the stored values to use for comparison
if notDefined('stored')
    dataFile        = [callingFunction(3:end) '.mat']; % lop off the 's_'
    vFile = fullfile(mrvDataRootPath,'validate', dataFile);
    stored = load(vFile);
end

%% call the validate function to recompute the values
if notDefined('val'), val = eval(callingFunction);   end
if notDefined('resave'), resave = false; end

names = fieldnames(stored);

%% Check whether stored and val are equal (within error tolerance) to the
% recomputed by the validation function
if ~isequal(stored,val)
    str = cell(1,length(names));
    OK = 0;
    for ii=1:length(names)
        if any(abs(stored.(names{ii}) - val.(names{ii})) > 100*eps)
            d = abs(stored.(names{ii}) - val.(names{ii}))/eps;
            str{ii} = sprintf('Mis-match for parameter: %s',names{ii});
            str{ii} = strvcat(str{ii}, ...
                sprintf('Stored: %f Computed: %f Num eps: %f\n', ...
                 stored.(names{ii}),val.(names{ii}),d));
        else
            str{ii} = sprintf('Valid parameter: %s', names{ii});
        end
    end
else
    OK = 1;
    str = sprintf('%s validated\n',callingFunction);
end

%% Get information regarding the software enviromnet if requested
env  = mrvGetEvironment();

%% Resave the data if there is a discrepancy and resave is requested
if resave && ~OK
    dataFile        = [callingFunction(3:end) '.mat']; % lop off the 's_'
    vFile = fullfile(mrvDataRootPath,'validate', dataFile);
    save(vFile, '-struct', 'val','env');
    fprintf('Resaved validation data in %s with new calculation.\n', dataFile);
end

return


