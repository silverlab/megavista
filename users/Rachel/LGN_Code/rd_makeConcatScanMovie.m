% rd_makeConcatScanMovie.m

%% Initializations
scans = 10:13;
ims = 5:139;
imMov = [];
slice = 10;
saveDiffMag = 1;
exportMovie = 1;

nScans = length(scans);
nIms = length(ims);

%% File I/O
diffMagFile = sprintf('Quality_Control/diffMag_slice%d_scans%d-%d.mat',slice,scans(1),scans(end));
movieFile = sprintf('Quality_Control/movie_slice%d_scans%d-%d.avi',slice,scans(1),scans(end));

%% Load data
for iScan = 1:nScans
    for iIm = 1:nIms
%         scanFilePath = sprintf('Inplane/Original/TSeries/Analyze/Scan%d.img',scans(iScan)); % MC
        % scanFilePath = 'epi02_mp/epi02_mp.img' % no MC
        scanFilePath = sprintf('epis/rfRD_WC-%04d-%05d-%06d.img',scans(iScan),ims(iIm),ims(iIm)); % SPM MC_
        scan = readFileNifti(scanFilePath);
        imMov = cat(4, imMov, scan.data);
    end
end
nTRs = size(imMov,4);

%% Calculate difference movie
diffMov = diff(imMov,1,4);

%% Calculate display ranges
% for the image movie
minVal = min(min(min(min(imMov))));
maxVal = max(max(max(max(imMov))));
displayRangeIm = [minVal maxVal];
fprintf('Image display range: [%d %d]\n',minVal,maxVal)

% for the difference movie
minVal = min(min(min(min(diffMov))));
maxVal = max(max(max(max(diffMov))));
displayRangeDiff = [minVal maxVal];
fprintf('Difference display range: [%d %d]\n',minVal,maxVal)

%% Calculate rms magnitude of difference movie over time
imMag = squeeze(sqrt(mean(mean(mean(imMov.^2)))));
diffMag = squeeze(sqrt(mean(mean(mean(diffMov.^2)))));

%% Show diff mag
figure
plot(diffMag)
xlabel('TR')
ylabel('TR-TR difference RMS')
title(['Slice ' num2str(slice)])

%% Show im and diff mag and their relationship
figure
subplot(3,1,1)
plot(imMag)
title('image RMS')
subplot(3,1,2)
plot(diffMag)
title('difference RMS')
subplot(3,1,3)
plot(imMag(2:end),diffMag,'.')
xlabel('image RMS')
ylabel('difference RMS')

%% Play movie
movs = {imMov, diffMov};
displayRanges = {displayRangeIm, displayRangeDiff};

M = rd_showSideBySideSliceMovie(movs, slice, displayRanges);

%% Export movie as avi
if exportMovie
    movie2avi(M,movieFile);
end

%% Save diffMag in mat file
if saveDiffMag
    save(diffMagFile,'diffMag')
end

%% Tiny script to concatenate diffMags and save single figure
% diffMag1 = load('Quality_Control/diffMag_slice10_scans5-9.mat');
% diffMag2 = load('Quality_Control/diffMag_slice10_scans10-13.mat');
% diffMag = [diffMag1.diffMag; diffMag2.diffMag];
% figure
% hold on
% plot(diffMag)
% plot(0:135:length(diffMag)+5,120,'.r','MarkerSize',10)
% xlabel('TR')
% ylabel('TR-TR difference RMS')
% title('Scans 5-13, slice 10')
