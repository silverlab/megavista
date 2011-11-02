function [S1, S2] = cellStructUnion(S1, S2)
%Make two cell array structures similar.
%
% [S1, S2] = function cellStructUnion(S1, S2)
%
% Input: two arrays of cell structures that may or may not contain similar fields.
% Output: the same structures where the fields that existed in one
% structure and not another are added (initialize as empty) to another
% structure.
%
% HISTORY:
% ER wrote it 03/2010

AllFields = union(fieldnames(S1(1)), fieldnames(S2(1)));

for f=1:length(AllFields)
    if ~isfield(S1(1), AllFields{f})
        S1(1).(AllFields{f})=[];
    end
    if ~isfield(S2(1), AllFields{f})
        S2(1).(AllFields{f})=[];
    end

end
