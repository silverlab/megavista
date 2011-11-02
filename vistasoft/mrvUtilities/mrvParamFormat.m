function sformatted = mrvParamFormat(s)
% Converts s to a standard mrVista parameter format  (lower case, no spaces)
%
%    sformatted = mrvParamFormat(s)
%
% The string is sent to lower case and spaces are removed.
%
% Example:
%     ieParamFormat('Exposure Time')
%
% See also: sensorGet, and so forth
%
% Copyright ImagEval Consultants, LLC, 2010

if ~ischar(s), error('s has to be a string'); end

% Lower case
sformatted = lower(s);

% Remove spaces
sformatted = strrep(sformatted,' ','');

return;


