function bool = checkfields(s,varargin)
%
%  bool = checkfields(s,varargin)
%
%Author:  Wandell
%Purpose:
%   We often need to check for a nest sequence of fields within a structure.  
% We have been doing this with a series of nested or grouped isfield statements.
% This got annoying, so I wrote this routine as a replacement.
%
% Suppose there is a structure, pixel.OP.pd.type
% You can verify that the sequence of nested structures is present via the
% call
%
%      checkfields(pixel,'OP','pd','type')
%
% A return value of 1 means the field sequence is present * and nonempty*.
% A return value of 0 means the sequence is absent or empty.
%
% ras, 07/05: imported into mrVista 2.0 repository.
% ras, 12/06: made so it checks if the field is nonempty as well.

nArgs = length(varargin);
str = 's';
tst = eval(str);

for ii=1:nArgs
    if isfield(tst,varargin{ii})
        % Append the argument to the current string
        str = sprintf('%s.%s',str,varargin{ii});

        % If this is the last one, return succesfully
        if ii==nArgs  & ~isempty(str)
            bool = 1;
            return;
        else
            tst = eval(str);
        end
    else
        bool = 0;
        return;
    end
end

% Should never get here
error('checkfields: Error')
return;


