function fgOut = fgExtract(fg,list)
% Select a subset of fibers and create a new group
%
%   fgOut = fgExtract(fg,list)
%
% fg:     a fiber group.
% list:   the specific fibers you want to extract
% fgOut:  the fg fibers in the list, with certain other fields preserved.
%
% Quench statistics (if any) are cleared as part of the extraction.
%
% N.B. There may be problems with this routine preserving some of the
% associated variables (e.g., seeds, Q, and other properties computed from
% the fibers).  We preserve some of them, but we clear others (e.g. pathway
% statistics).
%
% See also: fgTensors, dtiClearQuenchStats, fgSet/Get 
%
% Example:
%   fg = dtiGet(dtiH,'fiber groups',1);
%   nFibers = fgGet(fg,'n fibers');
%   list = 1:5:nFibers;
%   fgSmall = fgExtract(fg,list);
%   fgGet(fgSmall,'n fibers')
%
% (c) Stanford VISTA Team

% TODO:  This has many problems.  See below.

if notDefined('list'), error('list is required'); end
if all(list == 0), error('list has all zero entries, fibers will not be extracted.'), end

% Statistics are no longer valid.  So start with that.
fgOut = dtiClearQuenchStats(fg);

% Get the fibers
foo = cell(length(list),1);
for ii=1:length(list)
    foo{ii} =  fg.fibers{ii};
end
fgOut.fibers = foo;

% If there are tensors, get them too.  See fgTensors
if isfield(fgOut,'Q') && ~isempty(fgOut.Q)
    foo = cell(length(list),1);
    for ii=1:length(list), foo{ii} = fg.Q{ii}; end
    fgOut.Q = foo;
end

if isfield(fgOut,'seeds') && ~isempty(fgOut.seeds)
    fgOut.seeds = fgOut.seeds(list);
end

return
