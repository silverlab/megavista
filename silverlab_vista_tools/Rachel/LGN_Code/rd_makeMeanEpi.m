% rd_makeMeanEpi.m
%
% read in several 4d epi files and make mean epi. option to save nifti
% file

%% setup
scans = 1:12;
nScans = length(scans);

matrixSize = 128;
nSlices = 19;
voxelSize = [1.5 1.5 1.575];

saveMatFile = 1;
saveNiftiFile = 0;

% directory for 4d nifti file
inplaneDir = 'Inplane/Original/TSeries/Analyze';
fileNameMat = 'Inplane/MeanEpi';
fileNameNifti = 'Inplane/MeanEpi';

% initialize scanMeans
scanMeans = zeros(matrixSize, matrixSize, nSlices, nScans);

%% calculate mean epi
% mean for each scan -- read in one scan at a time to conserve memory
for iScan = 1:nScans
    scanNum = scans(iScan);
    inplaneScan = readFileNifti(sprintf('%s/Scan%d.img', inplaneDir, scanNum)); % inplane
    
    scanMeans(:,:,:,iScan) = mean(inplaneScan.data,4);
end

% mean across scans
meanEpi = mean(scanMeans,4);

% transpose to match gems
for iSlice = 1:19
    meanEpiT(:,:,iSlice) = meanEpi(:,:,iSlice)';
end

% show mean epi slices
rd_plotSlices(meanEpi);
    
%% save epi -- mat
if saveMatFile
    save(fileNameMat, 'meanEpi');
    save([fileNameMat 'T'], 'meanEpiT');
end
    
%% save epi -- nifti
if saveNiftiFile
    header.voxelsize = voxelSize;
%     header.origin = [-90 -126 -72]; % can find from anat file, or use [0 0 0]
    header.descrip = sprintf('Created by rd_makeMeanEpi > tfiWriteAnalyze on %s', date);
    [hbytes,imbytes,scalefac]=tfiWriteAnalyze(fileNameNifti,header,meanEpi);
    fprintf('\n\nFile saved as %s.\n\n', fileNameNifti)
    
    [hbytest,imbytest,scalefact]=tfiWriteAnalyze([fileNameNifti 'T'],header,meanEpiT);
    fprintf('\n\nFile saved as %s.\n\n', fileNameNifti)
end