% This function needs to be rewritten using the new model struct, and not
% the older params struct.
%
%function params = smMakeMeshImages(params, hemi)
% % function params = smMakeMeshImages(params, hemi)
% %
% % Purpose: Saves images of surface model receptive fields on the mesh. The
% % receptive field is displayed in a mrVista parameter map. 
% %
% % JW 12.2008
% %
% 
% %-------------------------------------------------------------------------
% cd(params.projectdir)
% 
% mrVista 3
% 
% % Get the view structure
% v = getCurView;
% 
% %-------------------------------------------------------------------------
% 
% mrGlobals;
% 
% % Load roiY and get coords
% v = loadROI(v, {params.roiX, params.roiY}, [], [], [], 1);
% v = viewSet(v, 'selectedroi', params.roiY);
% coords = v.ROIs(v.selectedROI).coords;
% 
% 
% % Open a 3D mesh
% try
%     [v, OK] = meshLoad(v,params.mesh(hemi),1);
%     warning('[%s]: Could not open a stored mesh', mfilename');
% catch
%     [v, OK] = meshLoad(v,[],1);
% end
%     
% % Open a stored view setting of the mesh 
% try 
%     meshRetrieveSettings(viewGet(v, 'CurMesh'), ...
%         sprintf('%s2%s', params.roiX, params.roiY));
% catch
%      f = msgbox('Please adjust the mesh. Then press OK');
%      waitfor(f);
%      disp('done!')
% end
% 
% % Check to see if there is an image dir. If not, make one.
% if ~checkfields(params, 'imdir');
%     params.imdir = fullfile(params.analysisdirFull, 'smImages');
% end
% if ~isdir(params.imdir), mkdir(params.imdir); end
% 
% %--------------------------------------------------------------------------
% % Loop through the voxels, making one image per voxel
% ii = params.roiYsampleRate;
% 
% for vox = ii:ii:size(coords,2);
% 
%     % create a point-ROI for the VOI in order to display it on the mesh
%     pt = coords(:, vox);
%     v = newROI(v, sprintf('%s_%d', params.roiY, vox),1,'k',pt); 
%     
%     % name the voxel by its index and its 3D coords
%     vname = sprintf...
%         ('%s-%d-[%d-%d-%d]', params.roiY, vox,...
%         coords(1, vox), coords(2, vox), coords(3, vox));
%     
%     % load the parameter map
%     mappath = fullfile(params.mapdir,...
%         sprintf('%s_%dmap.mat', params.roiY, vox));
%     v = loadParameterMap(v, mappath);
%     
%     % make it look nice
%     v.ui.mapMode=setColormap(v.ui.mapMode, 'jetCmap');
%     mapwin = viewGet(v, 'mapwin');
%     v = viewSet(v, 'mapwin', [0.1 mapwin(2)]);
%      
%     % update the mesh
%     v = meshColorOverlay(v);
% 
%     % save an image of the mesh
%     img = mrmGet( viewGet(v, 'Mesh'), 'screenshot' ) ./ 255;
%     hTmp = figure('Color', 'w');
%     imagesc(img);
%     axis image; axis off;
%     title(vname);
%     saveas(hTmp, fullfile(params.imdir, [vname '.jpg']));
%     close(hTmp)
%     clear hTmp;
% 
%     % get ready to start again by clearing the ROIs, refreshing the view
%     v=deleteROI(v,v.selectedROI);
%     v=refreshScreen(v,0);
% end
% %--------------------------------------------------------------------------
% 
% return