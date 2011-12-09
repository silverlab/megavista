% roi2voxruns_combineVoxels.m
%
% convert ROI timeseries from individual runs to individual voxel time
% series for several runs. special twist: average multiple voxels' time
% series into a new combined voxel to compare across different scanning
% resolutions.
%
% run this from ROIAnalysis directory (to load in ROIs)

% addpath(genpath('/Volumes/Plata1/LGN_Localizer/Code/'))

nVoxToCombine = 4;

roiName = 'lgnROI1-2';
nROIs = 2;
scans = 1:6;
roiDate = '20101118';

tmpROIDir = 'roi_tmp';
voxDir = 'vox_data';

% ** no need to run all of this if temporary roi files already exist **
% % load ROIs from each scan and save them in temporary files as var 'roi'
for iScan = 1:length(scans)
%     
%     scan = scans(iScan);
% 
%     dataFile{iScan} = sprintf('%sData_Scan%d_%s.mat', roiName, scan, roiDate);
%     load(dataFile{iScan});
%     
%     roi = lgnROI1;
    tmpFile{1,iScan} = sprintf('roi%02d_scan%02d.mat', 1, iScan);
%     save(sprintf('%s/%s', tmpROIDir, tmpFile{1,iScan}),'roi');
%     
%     roi = lgnROI2;
    tmpFile{2,iScan} = sprintf('roi%02d_scan%02d.mat', 2, iScan);
%     save(sprintf('%s/%s', tmpROIDir, tmpFile{2,iScan}),'roi');
%     
end

% for each ROI, load all the scans and combine voxels across scans
for iROI = 1:nROIs
    
    for iScan = 1:length(scans)
        
        load(sprintf('%s/%s', tmpROIDir, tmpFile{iROI, iScan}));
    
        roiData{iROI}(:,:,iScan) = roi;  
        
    end
    
end

% now combine data across some number of voxels and save each combined
% voxel's data across scans to a separate file
for iROI = 1:nROIs
    
    nVox = size(roiData{iROI},2);
    nCVox = floor(nVox/nVoxToCombine); % number of combo voxels
    nVoxLeftOver = nVox - nCVox*nVoxToCombine;
    
    fprintf('\n\n**%d voxel(s) will not be included in the combined voxel data**\n\n', ...
        nVoxLeftOver)
    
    for iCVox = 1:nCVox
        
        iVoxs = ((iCVox-1)*nVoxToCombine + 1):(iCVox*nVoxToCombine);
        
        vox = squeeze(mean(roiData{iROI}(:,iVoxs,:),2))'; % [scans x time]
        
        voxID = sprintf('%s_roi%02d_vox%05d', datestr(now,'yyyymmdd'), iROI, iCVox);
        
        saveFile = sprintf('%s/cvoxdata_%s.mat', voxDir, voxID);
        
        save(saveFile, 'vox');
        
    end
    
end




    
    



