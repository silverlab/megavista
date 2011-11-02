function vw = roiRestricttoLayer1(vw, ROInum)
%
% vw = roiRestricttoLayer1(vw, [ROInum])
%
% Restricts ROI to layer 1 nodes.
%
% Example: vw = roiRestricttoLayer1(vw);

% Choose the ROI
if ~exist('ROInum','var')
   % error if no current ROI
   if vw.selectedROI == 0
      myErrorDlg('No current ROI');
   else      
      ROInum = vw.selectedROI;  
    end
end

% Get indices to ROI voxels and to all Gray nodes
inds.ROI = viewGet(vw, 'roigrayindices');
nodes.ROI = vw.nodes(:, inds.ROI);

layer1.ROI = nodes.ROI(6,:) == 1;

layer1.ROI = inds.ROI(layer1.ROI);


% Get current ROI coords
coords = vw.ROIs(ROInum).coords;

% Save prevSelpts for undo
vw.prevCoords = coords;



% Modify ROI.coords
vw.ROIs(ROInum).coords = vw.coords(:, layer1.ROI);

vw.ROIs(ROInum).modified = datestr(now);

vw.ROIs(ROInum).name = [vw.ROIs(ROInum).name '-Layer1'];

vw = refreshScreen(vw);


vw = viewSet(vw, 'CurrentROI', ROInum);

return