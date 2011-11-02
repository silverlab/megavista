function par = ecogEventsGroupConditions(par,groups,names)
% Groups should be a cell array of vectors, specifying which
% conditions should be grouped together in the new par struct.
% Conditions not included in groups will be kept as separate conditions.
%
% Names is a cell array of strings specifying the new labels assigned to
% the new conditions (same length as groups).
%
%   par = ecogEventsGroupConditions(par,groups,names)
%
% written amr March 23, 2010 based on Rory's tc_groupConditions
%

% group conditions in each group together
% (to avoid confusion between the old cond nums and the new, target
% cond nums, we first assign each new cond a negative, then multiply by -1)
for i = 1:length(groups)
	tgtConds = find( ismember(par.cond, groups{i}) );
	par.cond(tgtConds) = -i;
end

% find any remaining (positive) numbers, and assign them to the 
% remaining condition numbers
leftOver = find(par.cond > 0);
remainingConds = unique(par.cond(leftOver));

for i = 1:length(remainingConds)
	newVal = -1 * (length(groups) + i);  
	par.cond(par.cond==remainingConds(i)) = newVal;
	
	% grab the color/name of this leftover condition as well
	names = [names par.label{remainingConds(i)+1}];
end

% now, assign all to positive
par.cond = -1 * par.cond;

% ensure the null condition name/color is preserved
nNewConds = length( unique(par.cond) );
if length(names) < nNewConds
	names = [par.label{1} names];
end


% assign new cond names, colors
%par.cond = unique(par.cond);
for i = 1:length(groups)
	tgtNames = find( par.cond == i);
	par.label(tgtNames) = names(i);
end

return