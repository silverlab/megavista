function fullName = mrdUserInitials(initials);
% fullName = mrdUserInitials(initials);
%
% This is a (somehat inaccurately named) lookup table. Since many existing
% mrVISTA sessions have subject and operator names entered as initials,
% this remaps the initials into the name used in databases. (Hopefully this
% is the same as that used for things like vAnatomies, making this more
% generally useful, maybe?)
%
% Bonus: you can also enter a bunch of initials, as a cell; fullName will
% then also be a cell containing the full names.
%
% 03/04 ras.
if iscell(initials)
    for i = 1:length(initials)
        fullName{i} = mrdUserInitials(initials{i});
    end
    return;
end

switch initials
    case {'rs','ras'}
        fullName = 'rory';
    case {'kgs'}
        fullName = 'kalanit';
    case {'jw'}
        fullName = 'janelle';
    case {'da'}
        fullName = 'dave';
    case {'sh'}
        fullName = 'sven';
    case {'js'}
        fullName = 'jean';
    case {'jv'}
        fullName = 'joakim';
    case {'jl'}
        fullName = 'junjie';
    case {'aab'}
        fullName = 'alyssa';
    case {'bw','baw'}
        fullName = 'brian';
    case {'dbr'}
        fullName = 'ress';
    otherwise,
        fullName = [];
end

return
        