% rd_readRawDataMultiScan
%
% look at long raw time series from multiple scans in a session

roiCoords = lgnROI3Coords;
scans = 2:6;
nScans = length(scans);
nVox = size(roiCoords,2);
% nTRs = 80; % inplane
nTRs = 85; % raw pfiles

% directory for 4d nifti file
% inplaneDir = 'Inplane/Original/TSeries/Analyze';
inplaneDir = 'Raw/Pfiles';

% initialize inplane raw roi
inplaneRawROI = nan(nTRs, nVox, nScans);

% read in one scan at a time to conserve memory
for iScan = 1:nScans

    scanNum = scans(iScan);

%     inplaneScan = readFileNifti(sprintf('%s/Scan%d.img', inplaneDir, scanNum)); % inplane
    inplaneScan = readFileNifti(sprintf('%s/epi%02d.img', inplaneDir, scanNum)); % raw

    for iVox = 1:nVox

        voxNum = iVox;

        roiVoxCoords = roiCoords(:, voxNum);
        inplaneVoxCoords = roiVoxCoords([2 1 3]); % what is the coord mapping for raw pfiles?

        inplaneVoxTSeries = squeeze(inplaneScan.data(inplaneVoxCoords(1), ...
            inplaneVoxCoords(2), inplaneVoxCoords(3), :));

        inplaneRawROI(:,iVox,iScan) = inplaneVoxTSeries;

    end

end

% convert to long multi-scan tseries
inplaneRawROIMultiScanTSeries = nan(nTRs*nScans, nVox);

for iVox = 1:nVox

    voxMultiScan = squeeze(inplaneRawROI(:,iVox,:));
    voxMultiScanTSeries = reshape(voxMultiScan, nTRs*nScans, 1);
    
    inplaneRawROIMultiScanTSeries(:,iVox) = voxMultiScanTSeries;

end

% plot the whole time series from sample voxels
% for iVox = 1:100
% 
%     clf
%     hold on
%     ylim([3000 10000])
%     plot([nTRs:nTRs:nTRs*nScans],7000,'r+','MarkerSize',30)
% %     plot(inplaneRawROIMultiScanTSeries(:,iVox))
%     plot(rawmts(1:80,iVox))
%     title(num2str(iVox))
%     pause(1)
%     
% end

% save lgnROI3MTS_Raw.mat roiCoords scans nTRs inplaneDir inplaneRawROI inplaneRawROIMultiScanTSeries


