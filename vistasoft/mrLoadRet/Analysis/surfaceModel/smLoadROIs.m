function [vw] = smLoadROIs(model, vw)
% Opens the ROIs associated with a particular model
% model normally has 2 ROIs.
% if the model was STIMULUS -> ROI, then loads one ROI.

if ~isstruct(model.ROIs)
    error('ROI structure is corrupt in the model');
end

roiX = smGet(model, 'roix');
roiY = smGet(model, 'roiy');


if (~strcmpi(smGet(model, 'roixname'), 'stimulus'))
    if ~alreadyLoaded(vw, smGet(model, 'roixname')), 
        vw = addROI(vw, roiX);
    end
end

if (~strcmpi(smGet(model, 'roiyname'), 'stimulus'))
    if ~alreadyLoaded(vw, smGet(model, 'roiyname')), 
        vw = addROI(vw, roiY);
    end
end


%-----------------------------------------------------------------------
function loaded = alreadyLoaded(vw, roifile)

% get the currently loaded ROIs
curROIs = viewGet(vw, 'allroinames');

% chop off the '.mat' from the new ROI
[pth roiname ext] = fileparts(roifile);

% see if it already exists
loaded = ~isempty(cellfind(lower(curROIs), lower(roiname)));

return