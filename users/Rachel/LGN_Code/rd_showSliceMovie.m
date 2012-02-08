% rd_showSliceMovie.m
%
% This can be used to visually check the quality of motion correction. 

%% Initializations
scanFilePath = 'Inplane/Original/TSeries/Analyze/Scan10.img' % MC
% scanFilePath = 'epi02_mp/epi02_mp.img' % no MC
nSlices = 19;
nImCols = ceil(sqrt(nSlices));
nImRows = ceil(nSlices/nImCols);
slice = 9;
magnification = 300; % percent magnification
imageOption = 'difference';
imageScale = 'uniform';

%% Load data
scan = readFileNifti(scanFilePath);
nTRs = size(scan.data,4);
diffMov = diff(scan.data,1,4);

%% Save some data for later
scan_orig = scan;
diffMov_orig = diffMov;
scan_mc = scan;
diffMov_mc = diffMov;

%% Choose type of images to show and image scaling
switch imageOption
    case 'original'
        brainMov = scan.data;
        nTimepoints = nTRs;
    case 'difference'
        brainMov = diffMov;
        nTimepoints = nTRs-1;
end

switch imageScale
    case 'auto'
        displayRange = [];
    case 'uniform'
        minVal = min(min(min(min(brainMov))));
        maxVal = max(max(max(max(brainMov))));
        displayRange = [minVal maxVal];
        fprintf('Using display range [%d %d]\n',minVal,maxVal)
end

%% Play movie for a single slice over time
for t = 1:nTimepoints
    try
        imshow(brainMov(:,:,slice,t),...
            'DisplayRange',displayRange,...
            'InitialMagnification',magnification)
    catch
        imagesc(brainMov(:,:,slice,t))
        axis equal; axis off; 
        if t==1
            colormap gray; fprintf('Using imagesc ... auto scaling\n')
        end
    end
    pause(0.1)
end
fprintf('finished\n')
% slice = slice+1

%% Play movie for all slices over time
for t = 1:nTimepoints
    for iSlice = 1:nSlices
        subplot(nImRows,nImCols,iSlice)
        try
            imshow(brainMov(:,:,iSlice,t),...
                'DisplayRange',displayRange)
        catch
            imagesc(brainMov(:,:,iSlice,t))
            axis equal; axis off;
            if t==1 && iSlice==1
                colormap gray; fprintf('Using imagesc ... auto scaling\n')
            end
        end
    end
    pause(0.01)
end
fprintf('finished\n')

%% Choose two movies to compare
% mov1 = diffMov_orig(:,:,:,end-137:end); % nTRs-2
mov1 = diffMov_orig(:,:,:,2:end);
mov2 = diffMov_mc;
% mov1 = scan_orig.data(:,:,:,end-138:end); % nTRs-1
mov1 = scan_orig.data;
mov2 = scan_mc.data;

%% Play two slice movies side by side
rd_showSideBySideSliceMovie({mov1, mov2}, slice, displayRange);




