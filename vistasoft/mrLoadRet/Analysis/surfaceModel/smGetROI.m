function [ROI]  = smGetROI(vw, ROI, defaultNum)
% Subroutine to output an ROI struct. 
%   For use with surface models of BOLD activity. (see smMain.m)
%
% Inputs: 
%   vw: a mrVista view struct
%   ROI: can be 
%       (a) an ROI number indexing the ROIs loaded into vw
%       (b) an ROI string 
%       (c) an ROI struct (in which case we return without doing anything)
%       (d) undefined (in which case we rely on defaultNum)
%   defaultNum: an ROI number indexing the ROIs loaded into vw.
%               For use only if ROI is empty.
%
%   (D) and (a) may seem redundant but they are not.

% If ROI is a struct, return without doing anything
if isstruct(ROI)
    return;
end

% If ROI is undefined, try to find a ROI loaded in vw
if isempty(ROI),  
        vw  = viewSet(vw, 'selectedroi', defaultNum);
        ROI = viewGet(vw, 'roistruct');
        return;
end

% If ROI is a number, get the ROI struct in vw indexed by that number
if isnumeric(ROI)    
        nROIs = viewGet(vw, 'nROIs');
        if ROI > nROIs, 
            error('[%s]: ROI(%d) is not loaded in the current view', ROI); 
        end
        vw = viewSet(vw, 'selectedROI', ROI);
        ROI = viewGet(vw, 'ROIstruct');
        return;
end

% If ROI is a string, try to find it in vw, or else load it into vw
if ischar(ROI)
    % try to find the string among the cur ROIs in view
    nROIs = numel(viewGet(vw, 'rois'));
    for ii = 1:nROIs;
        vw = viewSet(vw, 'selectedroi', ii);
        tmp = viewGet(vw, 'roistruct');
        if strcmpi(tmp.name, ROI)
            ROI = tmp;
            return
        end
    end
    
    % if we are here we didn't find the ROI, so try to load it
    local = true;
    vw = loadROI(vw, ROI, [], [], [], local);
    ROI = viewGet(vw, 'roistruct');
        return
end

% if we are here then all attempts to get the ROI have failed
error('[%s]: cannot find ROI ''%s''. Aborting...', mfilename, ROI);

return