function handles = dtiRefreshFigure(handles, update3D)
% General routine for refreshing the display windows.
%
%   handles = dtiRefreshFigure(handles, update3D)
%
% General routine for refreshing the display windows.  The 3 planar cuts
% in the main window are updated.  If show3d is set, then the 3D Matlab
% window is updated.  If mrMesh is set then the mrMesh window is updated
% also.
%
% The handles may be modified, so they are returned.  They are not
% attached to the window here, but rather in the calling routine.
%
% The handles are the return from handles = guidata(gcf); where the current
% figure is the mrDiffusion (dtiFiberUI) window.  The dtiGet routines
% only use a subset of the returned handles.  I am not exactly sure why
% there are so many handles returned by the guidata call.  There are even
% more handles returned by the guihandles call.
%
% HISTORY: 
% ?????: Dougherty & Wandell wrote it.
% 2005.06.09 RFD: minor code optimizations to make refreshes closer to 'realtime'.
%
% (c) Stanford VISTA Team, 2008

% Default is do not update the 3d.  
% But if update3D = 1, then we update mrMesh and/or Matlab 3D window.
if ~exist('update3D','var') || isempty(update3D), update3D = 0; end

% Read the window settings to determine what we will show during the
% refresh. The handles contain data from the mrDiffusion GUI Window.
useMrMesh    = get(handles.cbUseMrMesh, 'Value');
show2dFibers = get(handles.cbShowFibers,'Value');
showMatlab3d = get(handles.cbShowMatlab3d,'Value');
showCurPosMarker  = get(handles.cbShowCurPosMarker, 'Value');
curPosition  = str2num(get(handles.editPosition, 'String'));
curBgNum = get(handles.popupBackground,'Value');
overlayThresh = get(handles.slider_overlayThresh, 'Value');
overlayAlpha = str2double(get(handles.editOverlayAlpha, 'String'));
curOvNum = get(handles.popupOverlay,'Value');

% Decide which FGs and ROIs to show
%showTheseFgs  = dtiFGShowList(handles);
showTheseRois = dtiROIShowList(handles);

% Refresh the ROI popup window.  
% Do we need to call this from here?
dtiFiberUI('popupCurrentRoi_Refresh',handles);

% Refresh the FG popup window.  
dtiFiberUI('popupCurrentFiberGroup_Refresh',handles);

% Retrieves information abaout the image slices in the three principal
% axes.  This routine needs to be divided up because sometimes we want part
% of the information, not all.
[xSliceRgb,ySliceRgb,zSliceRgb,anat,anatXform, ...
    mmPerVoxel,xform,xSliceAxes,ySliceAxes,zSliceAxes] = ...
    dtiGetCurSlices(handles);

% Show ROIs in three planar images
% dtiShowROIs(handles);
invXform = inv(xform);
curPosImg = round(mrAnatXformCoords(invXform,curPosition));
for ii=showTheseRois
    if(~isempty(handles.rois(ii).coords) && handles.rois(ii).visible)
      rgbaColor = dtiRoiGetColor(handles.rois(ii),0.5);
      coords = round(mrAnatXformCoords(invXform,handles.rois(ii).coords));
      % X (sagittal) slice
      sz = size(xSliceRgb);
      curSl = coords(:,1)==curPosImg(1);
      inds = sub2ind(sz(1:2),coords(curSl,2),coords(curSl,3));
      xSliceRgb(inds) = xSliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(1)*rgbaColor(4);
      inds = inds+sz(1)*sz(2);
      xSliceRgb(inds) = xSliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(2)*rgbaColor(4);
      inds = inds+sz(1)*sz(2);
      xSliceRgb(inds) = xSliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(3)*rgbaColor(4);
      % Y (coronal) slice
      sz = size(ySliceRgb);
      curSl = coords(:,2)==curPosImg(2);
      inds = sub2ind(sz(1:2),coords(curSl,1),coords(curSl,3));
      ySliceRgb(inds) = ySliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(1)*rgbaColor(4);
      inds = inds+sz(1)*sz(2);
      ySliceRgb(inds) = ySliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(2)*rgbaColor(4);
      inds = inds+sz(1)*sz(2);
      ySliceRgb(inds) = ySliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(3)*rgbaColor(4); 
      % Z (axial) slice
      sz = size(zSliceRgb);
      curSl = coords(:,3)==curPosImg(3);
      inds = sub2ind(sz(1:2),coords(curSl,2),coords(curSl,1));
      zSliceRgb(inds) = zSliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(1)*rgbaColor(4);
      inds = inds+sz(1)*sz(2);
      zSliceRgb(inds) = zSliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(2)*rgbaColor(4);
      inds = inds+sz(1)*sz(2);
      zSliceRgb(inds) = zSliceRgb(inds)*(1-rgbaColor(4))+rgbaColor(3)*rgbaColor(4); 
    end
end

handles = dtiShowInplaneImages(handles,xSliceAxes,xSliceRgb,ySliceAxes,ySliceRgb,zSliceAxes,zSliceRgb);

% Show fiber groups in three planar images
if show2dFibers, dtiShowFGs(handles); end

% Mark position point
if(showCurPosMarker), dtiShowCurPos(handles); end

% Reset the mouse-click callbacks (adding stuff to the axes resets them).
% Also, we have to turn the image object's hit-test off to allow mouse
% clicks to pass though to the axis object.
set(handles.z_cut_img,'HitTest','off');
set(handles.z_cut,'ButtonDownFcn','dtiFiberUI(''z_cut_click_Callback'',gcbo,[],guidata(gcbo))');
set(handles.y_cut_img,'HitTest','off');
set(handles.y_cut,'ButtonDownFcn','dtiFiberUI(''y_cut_click_Callback'',gcbo,[],guidata(gcbo))');
set(handles.x_cut_img,'HitTest','off');
set(handles.x_cut,'ButtonDownFcn','dtiFiberUI(''x_cut_click_Callback'',gcbo,[],guidata(gcbo))');

curBg = get(handles.popupBackground,'Value');
sz = size(handles.bg(curBg).img);
imCoord = round(inv(handles.bg(curBg).mat)*[curPosition 1]'); imCoord = imCoord(1:3)';
if(all(curPosImg>0) && all(imCoord<=sz(1:3)))
    curBgVal = squeeze(handles.bg(curBg).img(imCoord(1),imCoord(2),imCoord(3),:))';
    curBgVal = handles.bg(curBg).minVal+curBgVal*(handles.bg(curBg).maxVal-handles.bg(curBg).minVal);
    if(length(curBgVal)>1) 
        curBgValueStr = sprintf('%0.2f ',curBgVal);
    else
        curBgValueStr = num2str(curBgVal,4);
    end
else
   curBgValueStr = 'NaN';
end
curBgValueStr = [curBgValueStr ' ' handles.bg(curBg).unitStr];
set(handles.textImgVal,'String',curBgValueStr);

% Matlab 3d plots
% 
if ((showMatlab3d || useMrMesh) && (update3D))
    [zIm,zImX,zImY,zImZ] = dtiGetSlice(anatXform, anat, 3, curPosition(3), [], handles.interpType);
    [yIm,yImX,yImY,yImZ] = dtiGetSlice(anatXform, anat, 2, curPosition(2), [], handles.interpType);
    [xIm,xImX,xImY,xImZ] = dtiGetSlice(anatXform, anat, 1, curPosition(1), [], handles.interpType);
end

% Matlab 3D window
if (showMatlab3d && update3D)
    handles = dtiMatlab3dWindow(handles,zImX,zImY,zImZ,zIm,yIm,yImX,yImY,yImZ,xIm,xImX,xImY,xImZ); 
end

% MrMesh window (DTI)
if (useMrMesh)
    if(~isfield(handles,'mrMesh'))
        handles.mrMesh = [];
    end
    % Set the 3d cursor (the mrMesh 3d space is just ac-pc space)
    mrmSet(handles.mrMesh,'cursorRaw',curPosition);
    if(update3D)
        [xIm,yIm,zIm] = dtiMrMeshSelectImages(handles,xIm,yIm,zIm);
        origin = dtiGet(handles,'origin');
        handles = dtiMrMesh3AxisImage(handles,origin, xIm, yIm, zIm);
    end
end

%
% Update any other mrDiffusion windows yoked to this window
%
if(isfield(handles,'yokeTo')&&~isempty(handles.yokeTo))
    %handles.yokeTo = dtiGet(handles,'allMrdFigs');
    for(ii=1:length(handles.yokeTo))
        h = guidata(handles.yokeTo(ii));
        if(~isempty(h) && h.figure1~=handles.figure1)
            % *** TODO: Sanity-check these values!
            set(h.popupBackground,'Value',curBgNum);
            set(h.slider_overlayThresh, 'Value',overlayThresh);
            set(h.editOverlayAlpha, 'String',num2str(overlayAlpha));
            set(h.popupOverlay,'Value',curOvNum);
            % Finally, we can just call dtiFiberUI to set the last thing.
            % This will also trigger a refersh of that window.
            dtiFiberUI('setPositionAcPc', h, curPosition);
        else
            % Figure was probably closed- remove it from our list
            handles.yokeTo(ii) = [];
        end
    end
end

return;
