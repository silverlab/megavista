function roi = dtiRoiClean(roi, smoothKernel, flags)
% 
% roi = dtiRoiClean(roi, smoothKernel, flags)
%
% Cleans up a dti ROI. Flags is a cellarray of strings specifying various
% flags. The presence of a flag turns that option on, the absence turns it
% off. If nargin<3, the user will be prompted. Flags include:
%   * 'removeSatellites'
%   * 'fillHoles'
%   * 'dilate'
%
% smoothKernel defines the size of the convolution kernel (in voxels). Set
% to 0 for no smoothing. Can be a 1x3 (eg. [6,6,4] or a scalar for a
% symmetric kernel. Defaults to [3,3,3].
%
% HISTORY:
% 2005.01.05 RFD wrote it.

if(nargin<2)
    smoothKernel = 3;
    removeSatellites = 1;
    fillHoles = 1;
    dilate = 0;
    baseName = [roi.name '_cleaned'];
    resp = inputdlg({'smoothing kernel (0 for none):',...
        'remove satellites (0|1):','fill holes (0|1):','dilate (0|1):','Cleaned ROI name:'}, ...
    ['Clean ROI ' roi.name], 1, {num2str(smoothKernel), ...
        num2str(removeSatellites), num2str(fillHoles), num2str(dilate), baseName});
    if(isempty(resp)), disp('user cancelled.'); return; end
    smoothKernel = str2num(resp{1});
    removeSatellites = str2num(resp{2});
    fillHoles = str2num(resp{3});
    dilate = str2num(resp{4});
    roi.name = resp{5};
else
    fillHoles = 0;
    removeSatellites = 0;
    dilate = 0;
    if(nargin>2)
        flags = lower(flags);
        if(~isempty(strmatch('fillhole',flags))) fillHoles = 1; end
        if(~isempty(strmatch('removesat',flags))) removeSatellites = 1; end
        if(~isempty(strmatch('dilate',flags))) dilate = 1; end
    end
end
coords = roi.coords;
%bb = dtiGet(0, 'defaultBoundingBox');
bb = [floor(min(coords))-10; ceil(max(coords))+10];
roiMask = zeros(diff(bb)+1);
% Remove coords outside the bounding box
badCoords = coords(:,1)<=bb(1,1) | coords(:,1)>=bb(2,1) ...
       | coords(:,2)<=bb(1,2) | coords(:,2)>=bb(2,2) ...
       | coords(:,3)<=bb(1,3) | coords(:,3)>=bb(2,3);
coords(badCoords,:) = [];
% Convert from acpc space to matlab image space
%coords = mrAnatXformCoords(inv(dtiGet(handles, 'acpcXform')), coords);
coords(:,1) = coords(:,1) - bb(1,1) + 1;
coords(:,2) = coords(:,2) - bb(1,2) + 1;
coords(:,3) = coords(:,3) - bb(1,3) + 1;
coords = round(coords);
roiMask(sub2ind(size(roiMask), coords(:,1), coords(:,2), coords(:,3))) = 1;
roiMask = imclose(roiMask,strel('disk',2));
clear coords;
if(fillHoles) roiMask = imfill(roiMask,'holes'); end
roiMask = dtiSmooth3(roiMask, smoothKernel);
if(dilate~=0)
    if(dilate>0) roiMask = roiMask>0.1;
    else roiMask = roiMask>0.9; end
    if(fillHoles) roiMask = imfill(roiMask,'holes'); end
else
    roiMask = roiMask>0.5;
end
% FIXME! dtiCleanImageMask removes satalites AND fills holes. We should
% split these functions.
if(removeSatellites) roiMask = dtiCleanImageMask(roiMask, 0)>0.5; end
[coords(:,1), coords(:,2), coords(:,3)] = ind2sub(size(roiMask), find(roiMask));
coords(:,1) = coords(:,1) + bb(1,1) - 1;
coords(:,2) = coords(:,2) + bb(1,2) - 1;
coords(:,3) = coords(:,3) + bb(1,3) - 1;
%coords = mrAnatXformCoords(dtiGet(handles, 'acpcXform'), coords);
roi.coords = coords;
return;