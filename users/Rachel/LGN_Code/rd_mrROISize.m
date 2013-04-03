function roiVolume = rd_mrROISize(rois)

% Calculates ROI volume in mm^3 from Inplane ROIs
% rois is a cell array of ROI names (whatever they are saved as in the 
% Inplane/ROIs folder)
%
% part of this code is from editROIFields.m

%% setup
% rois = {'ROI101','ROI201'};
reportNVox = 0; % this involves starting up mrVista for each subjects (sorry)

if reportNVox
    %% start mrVista
    mrVista
    
    %% remove any ROIs already loaded
    INPLANE{1} = deleteAllROIs(INPLANE{1});
    INPLANE{1} = refreshScreen(INPLANE{1});
    
    %% load ROIs
    INPLANE{1} = loadROI(INPLANE{1}, rois);
    INPLANE{1} = refreshScreen(INPLANE{1});
    
    %% loop through ROIs
    for iROI = 1:numel(rois)
        %% get ROI size
        ROI = INPLANE{1}.ROIs(iROI);
        
        nVoxels = size(ROI.coords, 2);
        roiVolume(iROI) = nVoxels .* prod(viewGet(INPLANE{1}, 'voxelSize'))';
        
        %% get anatomical and functional sizes
        if nVoxels > 0
            funcVoxels = roiSubCoords(INPLANE{1}, ROI.coords);
            nFuncVoxels = size(funcVoxels,2);
        else
            error('No voxels in ROI!')
        end
        
        nGemsVox(iROI) = nVoxels;
        nEpiVox(iROI) = nFuncVoxels;
    end
    
    %% clean up from this subject
    close('all');
    mrvCleanWorkspace;
else
    %% just get the volume from the ROI and mrSESSION
    load mrSESSION
    
    for iROI = 1:numel(rois)
        load(sprintf('Inplane/ROIs/%s', rois{iROI}))
        nVoxels = size(ROI.coords, 2); % in GEMS coords
        voxelSize = mrSESSION.inplanes.voxelSize;
        roiVolume(iROI) = nVoxels .* prod(voxelSize)';
    end    
end


