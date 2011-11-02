function  [fg, originalIDs] = dtiShuffleFibers(fg)

%Shuffles fibers in a fibergroup. Useful if want to randomly sample a group
%of fibers from a fibergroup; first reshuffle them, then pick a continuous
%range of indices from the reshuffled fiber set.

%ER 03/2008 wrote it
%ER 08/2009 added output variable originalIDs
Nfibers=size(fg.fibers, 1); 

RandIndices=randsample(Nfibers, Nfibers);
fg.fibers=fg.fibers(RandIndices);
if ~isfield(fg, 'seeds') || isempty(fg.seeds) 
else
    fg.seeds=fg.seeds(RandIndices, :);
end

if ~isfield(fg, 'subgroup') || isempty(fg.subgroup)
else
    fg.subgroup=fg.subgroup(RandIndices);
end

originalIDs=RandIndices;