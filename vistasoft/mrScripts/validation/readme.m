% readme.m
%
% Purpose: 
%   Validation functions test various vistasoft functions. The validation
%   functions can be used to efficiently test wehther particular platforms
%   (OS, Matlab version) or repository updates cause problems with
%   vistasoft code. In particular, we would like to ensure that upon code
%   changes or platform changes, all validation functions run without error
%   and prodcue the correct output values. The validation functions run on
%   freely available sample data sets stored in the subversion repository,
%   vistadata.
%
% Requirements (see http://white.stanford.edu/newlm/index.php/Software)
%   vistasoft 
%   vistadata 
%
% Usage
%   The simplest and most comprehensive usage is to run the script
%   mrvValideAll. This can be called with or without a log file as input
%   and/or output:
%       mrvValidateAll
%       logfile = mrvValidateAll
%       mrvValidateAll('myLogFile.txt')
%       logfile = mrvValidateAll('myLogFile.txt')
%   This function will (a) search for all validation functions
%   of the form vistasoft/trunk/mrScripts/validation/v_*.m (b) run these
%   functions on sample data within the vistadata repository, (c) compare
%   the outputs of each function to stored values in vistadata, and (d)
%   generate a logfile summarizing the validation success of each function.
%   To test a single validation script, see help for mrvValide.m
%
% Adding new validation scripts
%   A validation script should take the form val = v_SomeFunctionality,
%   where <val> is a struct containing one or more values, preferably a
%   small number of summary statistics. See v_tSeries4D.m as an example.
%   This function loads the time series for all voxels in a sample data
%   set and stores the size, the mean, and the standard deviation of the
%   time series matrix. If all of the summary statistics match the stored
%   data, then we presume the whole tseries matches as well. When a
%   validation script is checked into the vistasoft repository, the
%   validation values (a matlab file containing <val>) should be checked
%   into the vistadata repository in the directory vistadata/validate/. See
%   tSeries4D.mat. It is important that the names are appropriately
%   matched. For example, if the validation function is v_myValidate.m,
%   then the matlab file must be called myValidate.mat. The validation
%   script and the validation data should both be checked in to their
%   respective repositories at the same time.
%
% Copyright Stanford team, mrVista, 2011
