function [anat, mmPerVoxel, xform, name, valRange, dispRange, unitStr] = dtiGetCurAnat(handles,getOverlayFlag)
%
% [anat, mmPerVoxel, xform, name, valRange, dispRange, unitStr] = dtiGetCurAnat(handles,[getOverlayFlag=0])
%
% valRange is the [min,max] of the original data.
%
% HISTORY:
% 2003.10.01 RFD (bob@white.stanford.edu) wrote it.
% 2004.07.03 xform comes back with a bad scale factor sometimes -- BW

% warning('Obsolete soon, I hope.');

if(~exist('getOverlayFlag','var') || isempty(getOverlayFlag) || ~getOverlayFlag)
    curAnatNum = get(handles.popupBackground,'Value');
else
    curAnatNum = get(handles.popupOverlay,'Value');
end

allNames = get(handles.popupBackground,'String');
name = allNames{curAnatNum};

anat = handles.bg(curAnatNum).img;
mmPerVoxel = handles.bg(curAnatNum).mmPerVoxel;
valRange = [handles.bg(curAnatNum).minVal,handles.bg(curAnatNum).maxVal];
xform = handles.bg(curAnatNum).mat;
dispRange = handles.bg(curAnatNum).displayValueRange;
unitStr = handles.bg(curAnatNum).unitStr;

return;
