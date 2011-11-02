function [view,pos] = addROI(view,ROI,select)
% Adds an ROI to the ROIs list of a view.
%
% [view,pos] = addROI(view,ROI,[select])
%
% If select is non-zero (the default), selects it.
% If requested, the position of the ROI in the list is passed
% back.
%
% If you change this function make parallel changes in:
%   all addROI*.m functions
%
% djh, 8/98
%
% AW/BW:  11.14.00 Modified for R12
%         When the view.ROIs is initialized to [], we cannot
%         assign it a structure in Matlab R12.  So, when it is null,
%         we remove the ROIs field before assigning.
if notDefined('select'), select=1; end

pos = 1;
if isfield(view,'ROIs')
    if isempty(view.ROIs),     view = rmfield(view,'ROIs');
    else                       pos = length(view.ROIs)+1;
    end
end

% check ROI format
roiFields = {'color' 'coords' 'name' 'viewType' ...
            'created' 'modified' 'comments'};
extra = setdiff(fieldnames(ROI), roiFields);
if ~isempty(extra)
    for f = extra, ROI = rmfield(ROI, f{1}); end
end

for f = fieldnames(ROI)'
    view.ROIs(pos).(f{1}) = ROI.(f{1});
end

if select
    view = selectROI(view,pos);
    % for volume views, find the ROI as it's loaded
    viewType = viewGet(view,'viewType');
    if (isequal(viewType,'Volume') || isequal(viewType,'Gray'))
        if checkfields(view, 'ui', 'sliceNumFields') && ~isempty(ROI.coords)
            view = selectCurROISlice(view);
            view = refreshScreen(view);
        end
    end
end

% Set the ROI popup menu
if checkfields(view, 'ui', 'popup')
    setROIPopup(view, {view.ROIs.name}, view.selectedROI);
end


return;
