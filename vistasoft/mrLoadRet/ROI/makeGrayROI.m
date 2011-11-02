function view = makeGrayROI(view,name,select,color)
%
% view = makeGrayROI(view,[name],[select],[color])
%
% Makes an ROI consisting of all of the gray.coords
%
% name: name (string) for the ROI (default = 'gray')
% select: if non-zero, chooses the new ROI as the selectedROI
%         (default=1).
% color: sets color for drawing the ROI (default 'b').
%
% djh, 2/15/2001
% 09/2005 ras, if non-gray view, makes it in a hidden gray and xforms over

% needs image size and nSlices
mrGlobals;

if ~strcmp(view.viewType,'Gray')
    % make a gray ROI in a hidden gray view,
    % and xform it over
    % (but, first check if a segmentation is installed)
    if ~exist(fullfile('Gray','coords.mat'))
        error('No Segmentation currently installed.');
    end
    
    dt = viewGet(view,'curdt');
    scan = viewGet(view,'curscan');
    hG = initHiddenGray(dt,scan);
    hG = makeGrayROI(hG);
    switch view.viewType
        case 'Inplane', view = vol2ipAllROIs(hG,view);
        case 'Flat', view = vol2flatAllROIs(hG,view);
        case 'Volume', view = addROI(view,hG.ROIs);
        otherwise, error('Unkown view type.');
    end
            
    return
end

if ~exist('name','var')
  name='gray';
end
if ~exist('select','var')
  select=1;
end
if ~exist('color','var')
  color=[.6 .6 .6]; % might as well make it gray...:)
end

ROI.name=name;
ROI.viewType=view.viewType;
ROI.coords=view.coords;
ROI.color=color;

[view,pos] = addROI(view,ROI,select);

return;
