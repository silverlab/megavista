% This script will load several subjects' dt6 files, load ROTS/LOTS ROIs,
% dilate the ROIs (8mm, etc), save the dilated ROIs, track fibers from
% these ROIs, and save these fibers.

% This sets the base directory and ROIs and loads the dt6 files
baseDir = 'Y:\data\reading_longitude\dti_adults'; %path to subjects' dti data on harddrive
f = {'bw040806', 'rd040630', 'ab050307', 'rk050524'};%subject directory list

% Parameters
radius = 30; % for sphere
smoothKernel = 8; % for dilating
opts.stepSizeMm = 1; % all opts are for tracking
opts.faThresh = 0.2;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.334 0.667];
distanceFromRoi = 0.87; % intersection parameter, minimum value because already dilated

%change to the appropriate directory, you call a variable
%as if it were a parameter in a function and put the string in parentheses
% cd(baseDir); 
for(ii=1:length(f))
    fname = fullfile(baseDir, f{ii}, [f{ii} '_dt6.mat']); %concatenates stuff in braket into one string, commas add slashes to create a valid path
    disp(['Processing ' fname '...']); %displays a string on the screen
    dt = load(fname); % this will load the dt6 file; you can doublechecheck by typing 'dt.dt6' and it will be a 3-D matrix + 1 more with 6 in it for the six diffusion directions
    %ROIs: load ROIs and create OTS folder
    roiName = {'ROTS_w123Vf', 'LOTS_w123Vf'}; %curly brackets are good for lists of strings ROI name list
    % fix so checks if folder already exists
    roiPath = fullfile(fileparts(fname), 'ROIs', 'OTSproject');
    if ~exist(roiPath,'dir')
        mkdir(fullfile(fileparts(fname), 'ROIs', 'OTSproject');
    end
    %create fiber folder and name
    fiberPath = fullfile(fileparts(fname), 'fibers', 'OTSproject');
    if ~exist(fiberPath,'dir')
        mkdir(fullfile(fileparts(fname), 'fibers', 'OTSproject'); 
    end

    for (jj=1:length(roiName))
        roiFileName = fullfile(roiPath,[roiName{jj} '.mat']);
        if exist(roiFileName,'file')
            roi = dtiReadRoi(roiFileName); % this should not have empty 'coords' field
            %dilate ROI
            cleanedRoi = dtiRoiClean(roi, smoothKernel, {'dilate'}); %other fields not written are set to 0
            cleanedRoi.name = [roiName{jj} '_dilate8'];
            %save dilated ROI
            dtiWriteRoi(cleanedRoi, fullfile(roiPath, [roiName{jj} '_dilate8.mat']));
            %build a sphere around the ROI
            sphereName = [roiName{jj} '_sphere' num2str(radius, '%02d')];
            roiSphere = dtiNewRoi(sphereName); %sphereName is in the .name field, see dtiNewRoi for more details
            centerCoord = round(mean(roi.coords,1)*10)/10; % mean: calculates on roi
            %[a structure with many fields, specify field with .], second item, 1, specifies mean over rows rather than columns [3 coord columns]
            roiSphere.coords = dtiBuildSphereCoords(centerCoord, radius);
            %save sphere ROI
            dtiWriteRoi(roiSphere, fullfile(roiPath, [roiSphere.name '.mat']));
            % track fibers from the sphere
            fgSphere = dtiFiberTrack(dt.dt6, roiSphere.coords, dt.mmPerVox, dt.xformToAcPc, [roiSphere.name '_FG'],opts);
            % this will save the fiber group
            dtiWriteFiberGroup(fgSphere, fullfile(fiberPath, [fgSphere.name '.mat']));
            %intersect BY ENDPTS fiber group with dilated roi
            fgRestricted = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, distanceFromRoi, cleanedRoi, fgSphere, inv(dt.xformToAcPc));
            % this will save the fiber group
            fgRestricted.name = [roiSphere.name '_AND_dilate8_FG'];
            dtiWriteFiberGroup(fgRestricted, fullfile(fiberPath, [fgRestricted.name '.mat']));
        end
    end
end