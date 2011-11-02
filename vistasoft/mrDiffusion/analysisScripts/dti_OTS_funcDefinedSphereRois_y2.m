% This script is based on 'dti_OTSfiberprocessing'. It will load several subjects' dt6 files, load ROTS/LOTS ROIs,
% grow a 30mm sphere in center of the functionally defined ROI, track
% fibers, restrict to those fibers that have endpoints in an 8mm sphere with the
% same center, and save these fibers.

% This sets the base directory, checks for LOTS/ROTS.mat files, and creates
% a list of appropriate subjects
baseDir = 'Y:\data\reading_longitude\dti_y2'; %path to subjects' dti data on harddrive
y1Dir = 'Y:\data\reading_longitude\dti';
cd(baseDir);
d = dir('*0*'); % lists all directories 
f = {d.name};

% Parameters
radius = 30; % for sphere
smallr = 8; % for endpoints
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
    fname = fullfile(baseDir, f{ii}, [f{ii} '_dt6_noMask.mat']); %concatenates stuff in braket into one string, commas add slashes to create a valid path
    disp(['Processing ' fname '...']); %displays a string on the screen

    % Find subject's corresponding y1 directory. Check if functional ROIS exist in year 1.
    % Find center coordinates of the ROIs. Sets 'y1' to equal 1 or 0. 
    roiName = {'LOTS','ROTS'}; %curly brackets are good for lists of strings ROI name list
    subject = f{ii};
    subject = subject(1:3);
    cd(y1Dir);
    % This will print the corresponding Y1 directory -- go back and check
    % if this is correct
    eval(['d=dir(''' num2str(subject) '*'')']);
    roiPath = fullfile(y1Dir, d.name, 'ROIs', 'OTSproject');
    for (ll=1:length(roiName))
        y1roi = fullfile(roiPath,[roiName{ll} '.mat']);
        if exist(y1roi,'file')
            roi = dtiReadRoi(y1roi); % this should not have empty 'coords' field
            centerCoords = round(mean(roi.coords,1)*10)/10; % finds center of ROI
            if ll==1
                center_left = centerCoords;
                left = 1;
            elseif ll==2
                center_right = centerCoords;
                right = 1;
            end
        elseif ll==1
            left =0;
        elseif ll==2
            right=0;
        end
    end

    cd(baseDir);
    dt = load(fname); % this will load the dt6 file; you can doublechecheck by typing 'dt.dt6' and it will be a 3-D matrix + 1 more with 6 in it for the six diffusion directions

    % Apply the brain mask if it exists. (Older dt6 files with no dtBrainMask field are implicitly masked.)
    % Code suggested by Bob so fibers are not tracked outside the brain
    % (8/23/2006)
    if(isfield(dt,'dtBrainMask'))
        dt.dt6(repmat(~dt.dtBrainMask, [1,1,1,6])) = 0;
    end

    %Checks for OTSproject directories and creates them if they do not exist
    roiName = {'LOTS', 'ROTS'}; %curly brackets are good for lists of strings ROI name list
    roiPath = fullfile(fileparts(fname), 'ROIs', 'OTSproject');
    if ~exist(roiPath,'dir')
        mkdir(fullfile(fileparts(fname), 'ROIs', 'OTSproject'));
    end
    fiberPath = fullfile(fileparts(fname), 'fibers', 'OTSproject');
    if ~exist(fiberPath,'dir')
        mkdir(fullfile(fileparts(fname), 'fibers', 'OTSproject'));
    end

    % If ROI exists, load it, and analyze it.
    for (jj=1:length(roiName))
        roiFileName = fullfile(roiPath,[roiName{jj} '.mat']);
        if (jj==1 & left==1) | (jj==2 & right==1)
            % Get center coordinates from proper ROI
            if jj==1
                centerCoord = center_left;
            elseif jj==2
                centerCoord = center_right;
            end

            % FINDS CENTER OF FUNCTIONAL ROI AND BUILDS A SMALL 8MM SPHERE ROI
            smallName = [roiName{jj} '_sphere' num2str(smallr, '%01d')];
            smallSphere = dtiNewRoi(smallName, 'r');
            smallSphere.coords = dtiBuildSphereCoords(centerCoord, smallr); % builds sphere of radius 30
            dtiWriteRoi(smallSphere, fullfile(roiPath, [smallSphere.name '.mat'])); % save sphere ROI

            % FINDS CENTER OF FUNCTIONAL ROI AND BUILDS A 30MM SPHERE ROI
            sphereName = [roiName{jj} '_sphere' num2str(radius, '%02d')];
            bigSphere = dtiNewRoi(sphereName, 'r'); %sphereName is in the .name field, see dtiNewRoi for more details
            bigSphere.coords = dtiBuildSphereCoords(centerCoord, radius); % builds sphere of radius 30
            dtiWriteRoi(bigSphere, fullfile(roiPath, [bigSphere.name '.mat'])); % save sphere ROI

            % TRACKS FIBERS FROM 30MM SPHERE
            fgSphere = dtiFiberTrack(dt.dt6, bigSphere.coords, dt.mmPerVox, dt.xformToAcPc, [bigSphere.name '_FG'],opts);
            dtiWriteFiberGroup(fgSphere, fullfile(fiberPath, [fgSphere.name '.mat'])); % saves fiber group

            %intersect BY ENDPTS fiber group with small sphere roi
            fgRestricted = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, distanceFromRoi, smallSphere, fgSphere, inv(dt.xformToAcPc));
            fgRestricted.name = smallSphere.name; % save the fiber group
            dtiWriteFiberGroup(fgRestricted, fullfile(fiberPath, [fgRestricted.name '.mat']));
        end
        clear smallSphere bigSphere fgSphere
    end
    clear left right centerCoord
end