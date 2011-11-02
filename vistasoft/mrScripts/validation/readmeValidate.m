% readmeValidate.m
%
% http://white.stanford.edu/newlm/index.php/Vistasoft_Validation
%
%   The validation functions are used to test whether vistasoft code runs
%   properly on a given platform (OS, Matlab version) and after updates to
%   the software repository. In particular, we would like to ensure that
%   upon code changes or platform changes, all validation functions run
%   without error and prodcue the correct output values. The validation
%   functions run on sample data sets stored in the subversion repository,
%   vistadata.
%
% Requirements (see http://white.stanford.edu/newlm/index.php/Software)
%   vistasoft 
%   vistadata 
%
% Usage
%   The simplest and most comprehensive use case is to run the script
%   mrvValidateAll. This can be called with or without a log file as input
%   and/or output:
%       mrvValidateAll
%       logfile = mrvValidateAll
%       mrvValidateAll('myLogFile.txt')
%       logfile = mrvValidateAll('myLogFile.txt')
%   This function will 
%   (a) search for all validation functions of the form
%       vistasoft/trunk/mrScripts/validation/v_*.m 
%   (b) run these functions on sample data within the vistadata repository, 
%   (c) compare the outputs of each function to stored values in vistadata, 
%   (d) generate a logfile.
%   To test a single validation script, see mrvValidate.m
%
% Adding new validation scripts
%   A validation script should take the form val = v_someFunctionality,
%   where <val> is a struct containing one or more values, preferably a
%   small number of summary statistics. See v_tSeries4D.m as an example.
%   This function loads the time series for all voxels in a sample data set
%   and calculates the size, mean, and  standard deviation of the time
%   series matrix. If the calculated summary statistics match the stored
%   summary statistics, then we presume the whole tseries matches as well.
%   When a validation script is checked into the vistasoft repository, the
%   validation values (a matlab file containing <val>) should be checked
%   into the vistadata repository in the directory vistadata/validate/. See
%   tSeries4D.mat. It is important that the names are appropriately
%   matched. For example, if the validation function is v_myValidate.m,
%   then the matlab file must be called myValidate.mat. 
%
% Copyright Stanford team, mrVista, 2011 (Jon Winawer)
