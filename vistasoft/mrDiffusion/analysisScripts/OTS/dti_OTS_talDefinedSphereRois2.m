% This script will loop on subjects' dt6 files, make ROTS/LOTS ROIs in a tal location,
% save the ROIs, track fibers from a 30mm sphere and restrict to those that have endpoints in an 8mm
% sphere, and save these fibers.

% This sets the base directory and ROIs and loads the dt6 files
baseDir = 'Y:\data\reading_longitude\dti_y2'; %path to subjects' dti data on harddrive
cd(baseDir);

% Use this code if you want to do everybody all at once
d = dir('*0*'); % lists all directories 
f = {d.name};

% Use this code if you want to do only a handful of preselected people
%f = {'ab040913', ...};

% Parameters
radius = 30; % for sphere
smoothKernel = 8; % for dilating
opts.stepSizeMm = 1; % all opts are for tracking
opts.faThresh = 0.15;
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
    roiName = {'LOTS','ROTS'}; %curly brackets are good for lists of strings ROI name list
    talCoords = [-42,-57,-6; 42,57,6];
    roiPath = fullfile(fileparts(fname), 'ROIs', 'OTSproject');
    if ~exist(roiPath,'dir')
        mkdir(fullfile(fileparts(fname), 'ROIs', 'OTSproject'));
    end
    %create fiber folder and name
    fiberPath = fullfile(fileparts(fname), 'fibers', 'OTSproject');
    if ~exist(fiberPath,'dir')
        mkdir(fullfile(fileparts(fname), 'fibers', 'OTSproject'));
    end

    for jj=1:length(roiName)
        % create 30mm sphere at tal location
        bigSphName = [roiName{jj} '_tal_sph30'];
        bigSphRoi = dtiNewRoi(bigSphName, 'r');
        centerCoordAcpc = mrAnatTal2Acpc(dt.anat.talScale, talCoords(jj,:));
        bigSphRoi.coords = dtiBuildSphereCoords(centerCoordAcpc, 30);
        dtiWriteRoi(bigSphRoi, fullfile(roiPath, [bigSphName '.mat']));

        % create 8mm sphere at tal location
        smallSphName = [roiName{jj} '_tal_sph8'];
        smallSphRoi = dtiNewRoi(smallSphName, 'r');
        smallSphRoi.coords = dtiBuildSphereCoords(centerCoordAcpc, 8);
        dtiWriteRoi(smallSphRoi, fullfile(roiPath, [smallSphName '.mat']));

        % track fibers from the big sphere

        %intersect BY ENDPTS fiber group with small sphere        
        fgSphere = dtiFiberTrack(dt.dt6, bigSphRoi.coords, dt.mmPerVox, dt.xformToAcPc, [bigSphRoi.name '_FG'],opts);
        % this will save the fiber group
        dtiWriteFiberGroup(fgSphere, fullfile(fiberPath, [fgSphere.name '.mat']));

        fgIntersected = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, distanceFromRoi, smallSphRoi, fgSphere, inv(dt.xformToAcPc));
        % this will save the fiber group
        fgIntersected.name = [roiName{jj} '_tal_sph8_FG'];
        dtiWriteFiberGroup(fgIntersected, fullfile(fiberPath, [fgIntersected.name '.mat']));
        clear fgSphere fgIntersected
    end

end