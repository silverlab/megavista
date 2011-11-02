function [xRgb,yRgb,zRgb,anat,anatXform,mmPerVox,xform,xAxes,yAxes,zAxes] = dtiGetCurSlices(handles)
% Determine current slices and return them (and potentially a lot of other info)
%
%  [xRgb,yRgb,zRgb,anat,anaXform,mmPerVox,xform,xAxes,yAxes,zAxes,outXform] = dtiGetCurSlices(handles)
%
%  Note: mmPerVox and xform are for the current space that the slices are
%  in, NOT the original image space. This is typically 1mm isotropic, ac-pc
%  aligned space.
%
% HISTORY: 
% ?????: Dougherty & Wandell wrote it.
% 2005.06.09 RFD: minor code optimizations to make refreshes closer to 'realtime'.
% 2006.11.08 RFD: default interpolation method is now nearest-neighbor
% rather than trilinear. We should make this a use option.
% 2006.11.10 RFD: interpolation method is now an option.
% 2009.06.16 RFD: added 0.5 offset to xAxes,yAxes,zAxes to make the axes
% tick marks line up with the voxel centers.
%
% Stanford VISTA Team

curPosition = dtiGet(handles, 'acpcpos');

overlayThresh = get(handles.slider_overlayThresh, 'Value');
overlayAlpha = str2num(get(handles.editOverlayAlpha, 'String'));

if(isfield(handles,'renderMm')&&~isempty(handles.renderMm))
    mmPerVox = handles.renderMm;
else
    mmPerVox = [1 1 1];
end

% anat = dtiGet(handles,'currentanatomydata');
% mmPerVoxel = dtiGet(handles,'mmPerVoxelCurrent');
% xform = dtiGet(handles,'currentAnatXform');
%
%[anat, anatMm, anatXform] = dtiGetCurAnat(handles);
curBgNum = get(handles.popupBackground,'Value');
anat = handles.bg(curBgNum).img;
anatXform = handles.bg(curBgNum).mat;
dispRange = handles.bg(curBgNum).displayValueRange;

bb = dtiGet(handles, 'defaultBoundingBox');
    
% The xform that we return is for the space that we put the slices in,
% which is ac-pc aligned on the specific sample grid (mmPerVox, typically
% 1mm isotropic) and filling the bounding box.
xform = [[diag(mmPerVox) bb(1,:)'-1];[0 0 0 1]];
% Here we get the transformed slices.
[zRgb,x,y,z] = dtiGetSlice(anatXform, anat, 3, curPosition(3), bb, handles.interpType, mmPerVox, dispRange);
zAxes = [x(1), x(end); y(1), y(end)]+0.5;
[yRgb,x,y,z] = dtiGetSlice(anatXform, anat, 2, curPosition(2), bb, handles.interpType, mmPerVox, dispRange);
yAxes = [x(1), x(end); z(1), z(end)]+0.5;
[xRgb,x,y,z] = dtiGetSlice(anatXform, anat, 1, curPosition(1), bb, handles.interpType, mmPerVox, dispRange);
xAxes = [y(1), y(end); z(1), z(end)]+0.5;
if(ndims(anat)==3)
    for(ii=2:3)
        zRgb(:,:,ii) = zRgb(:,:,1);
        yRgb(:,:,ii) = yRgb(:,:,1);
        xRgb(:,:,ii) = xRgb(:,:,1);
    end
elseif(ndims(anat)==4)
    % 3d views can only handle grayscale anatomy, so we'll just use a
    % luminance map from the RGB data.
    anat = mean(anat,4);
end

% Isn't this handled by dtiGetSlice already?  And differently?
xRgb(xRgb<0) = 0; xRgb(xRgb>1) = 1;
yRgb(yRgb<0) = 0; yRgb(yRgb>1) = 1;
zRgb(zRgb<0) = 0; zRgb(zRgb>1) = 1;

if(overlayAlpha>0)
    %[overlayImg, oMmPerVoxel, oXform] = dtiGetCurAnat(handles,1);
    curOvNum = get(handles.popupOverlay,'Value');
    overlayImg = handles.bg(curOvNum).img;
    oXform = handles.bg(curOvNum).mat;
    dispRange = handles.bg(curOvNum).displayValueRange;
    cmap = handles.cmaps(get(handles.popupOverlayCmap,'Value')).rgb;
    if(ndims(overlayImg)==3)
        % Here we get the transformed slices.
        oz = dtiGetSlice(oXform, overlayImg, 3, curPosition(3), bb, handles.interpType, mmPerVox, dispRange);
        oy = dtiGetSlice(oXform, overlayImg, 2, curPosition(2), bb, handles.interpType, mmPerVox, dispRange);
        ox = dtiGetSlice(oXform, overlayImg, 1, curPosition(1), bb, handles.interpType, mmPerVox, dispRange);
        mz = oz>overlayThresh;
        my = oy>overlayThresh;
        mx = ox>overlayThresh;
        oz = reshape(cmap(round(oz*255+1),:), [size(mz) 3]);
        oy = reshape(cmap(round(oy*255+1),:), [size(my) 3]);
        ox = reshape(cmap(round(ox*255+1),:), [size(mx) 3]);
        mx = repmat(mx,[1,1,3]);
        my = repmat(my,[1,1,3]);
        mz = repmat(mz,[1,1,3]);
        xRgb(mx) = (1-overlayAlpha).*xRgb(mx) + overlayAlpha.*ox(mx);
        yRgb(my) = (1-overlayAlpha).*yRgb(my) + overlayAlpha.*oy(my);
        zRgb(mz) = (1-overlayAlpha).*zRgb(mz) + overlayAlpha.*oz(mz);
    elseif(ndims(overlayImg)==4)
        % If there is a 4th dim, then this overlay is an RGB map.
        % dtiGetSlice will return an XxYx3 RGB slice.
        [oz,x,y,z] = dtiGetSlice(oXform, overlayImg, 3, curPosition(3), bb, handles.interpType, mmPerVox, dispRange);
        [oy,x,y,z] = dtiGetSlice(oXform, overlayImg, 2, curPosition(2), bb, handles.interpType, mmPerVox, dispRange);
        [ox,x,y,z] = dtiGetSlice(oXform, overlayImg, 1, curPosition(1), bb, handles.interpType, mmPerVox, dispRange);
        % We'll treat these differnt from the intensity image overlay case.
        % Rather than use a fixed transparency everywhere, we'll set the
        % transparency per-voxel by modulating it with the luminaince
        % component.
        if(overlayAlpha>1)
            % alpha>1 applies a gamma to the transparency map
            g = 1/overlayAlpha;
            overlayAlpha = 1;
        else
            g = 1;
        end
        lumz = repmat(mean(oz,3).^g,[1,1,3]);
        lumy = repmat(mean(oy,3).^g,[1,1,3]);
        lumx = repmat(mean(ox,3).^g,[1,1,3]);
        mz = lumz>overlayThresh;
        my = lumy>overlayThresh;
        mx = lumx>overlayThresh;
        xRgb(mx) = (1-lumx(mx).*overlayAlpha).*xRgb(mx) + lumx(mx).*overlayAlpha.*ox(mx);
        yRgb(my) = (1-lumy(my).*overlayAlpha).*yRgb(my) + lumy(my).*overlayAlpha.*oy(my);
        zRgb(mz) = (1-lumz(mz).*overlayAlpha).*zRgb(mz) + lumz(mz).*overlayAlpha.*oz(mz);        
    end
end

return;
