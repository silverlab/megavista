function fgArray=dtiFiberGroupToFgArray(fg)
%Convert an array of Fiber Groups into a fiber group with subgroups. 
% 
%   fgArray = dtiFiberGroupToFgArray(fg)
%
% PLEASE DEFINE what a fiber group with subgroup fields is.
% 
% Cell arrays of fiber groups are used pricipally by GUI functions, whereas
% a fiber group with subgroup field is as the preffered represenation for
% many scripts. Names are assigned based on subgroup names. 
%
% Example: 
%  fg = dtiLoadFiberGroup('myFiberGroup.mat');
%  fgArray = dtiFiberGroupToArray(fgArray, 'My new fiber group aray');  
%
% See also: dtiFgArrayToFiberGroup
%
% (c) Stanford VISTA Team, 2010

if ~isfield(fg, 'subgroup')
    fgArray=fg;
    return
end

subgroupVals = unique(fg.subgroup);

% Create an array of fiber groups.  Each one corresponds to a single name
% type of fibers.  The name is attached.
fgArray = struct(1,length(subgroupVals));
for iFG=1:length(subgroupVals)
    fgArray(iFG) = fg; 
    fgArray(iFG).fibers = fg.fibers(fg.subgroup==subgroupVals(iFG));
    fgArray(iFG).name = [fgArray(iFG).name '--' ...
        fg.subgroupNames(vertcat(fg.subgroupNames(:).subgroupIndex)==subgroupVals(iFG)).subgroupName];
    
end

fgArray = rmfield(fgArray, {'subgroup', 'subgroupNames'});
 
return
