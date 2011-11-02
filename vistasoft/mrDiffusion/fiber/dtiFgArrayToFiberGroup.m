function fg=dtiFgArrayToFiberGroup(fgArray, newFgName)
%Convert an array of Fiber Groups into a fiber group with subgroups. 
% 
%  fg=dtiFgArrayToFiberGroup(fgArray, newFgName)
%
% Arrays of fiber groups are used pricipally by GUI functions, whereas a
% fiber group with subgroup field is as the preferred represenation for
% many scripts that ER wrote.
%
% Example: 
%  fgArray = dtiReadFibers('myFiberGroupArray.mat');
%  fg = dtiFgArrayToFiberGroup(fgArray, 'My new fiber group');  
%
% See also: dtiFgFiberGroupToArray
%
% (c) Stanford Vistalab
%
% HISTORY: ER wrote it 11/2009

if ~exist('newFgName', 'var')|| isempty(newFgName)
    newFgName = 'fiber groups connecting multiple ROIs'; %This was for a specific project and needs to go
end

fg = dtiNewFiberGroup(newFgName);
fg.subgroup = []; fgInd = 0;
for ii = 1:size(fgArray, 1)
    for jj = ii+1:size(fgArray, 2)
        if ~isempty(fgArray(ii, jj))&& ~isempty(fgArray(ii, jj).fibers)
            fgInd = fgInd+1;
            fg.fibers = vertcat(fg.fibers, fgArray(ii, jj).fibers);
            fg.subgroup = horzcat(fg.subgroup, repmat(fgInd, [1 length(fgArray(ii, jj).fibers)]));
            fg.subgroupNames(fgInd).subgroupIndex = fgInd;
            fg.subgroupNames(fgInd).subgroupName = fgArray(ii, jj).name;
        end
    end
end

return