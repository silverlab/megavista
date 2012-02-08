function varargout = rd_showSideBySideSliceMovie(movs, slice, displayRanges)
% function M = rd_showSideBySideSliceMovie(movs, slice, displayRanges)
%
% movs is a cell array of brain movies
% slice is the slice number for all movies
% displayRange is a two-element vector giving the max and min gray value. 
%   set to [] for auto scaling. Or it can be a cell array of such vectors,
%   the same length as movs.
if nargout==0
    generateMovie = 0;
elseif nargout==1
    generateMovie = 1;
elseif nargout > 1
    error('Too many output arguments')
end

nMovs = length(movs);

% if displayRange is a single vector, make displayRanges
if ~iscell(displayRanges)
    displayRange = displayRanges;
    displayRanges = cell(1,nMovs);
    for iMov = 1:nMovs
        displayRanges{iMov} = displayRange;
    end
end

for iMov = 1:nMovs
    timepoints(iMov,1) = size(movs{iMov},4);
end
nJointTimepoints = min(timepoints);

f = figure;
for t = 1:nJointTimepoints
    for iMov = 1:nMovs
        subplot(1,nMovs,iMov)
        if isempty(displayRanges{iMov})
            imagesc(movs{iMov}(:,:,slice,t))
        else
            imagesc(movs{iMov}(:,:,slice,t),displayRanges{iMov})
        end
        axis equal; axis off;
        if t==1
            colormap gray
        end
    end
    if generateMovie
        M(t) = getframe(f);
    else
        pause(0.1)
    end
    
end
fprintf('finished\n')

if nargout==1
    varargout = {M};
end