% DY 02/27/2007
%
% This script will load several subjects' dt6 files, 30mm restricted to 8mm
% sphere fibers (sphere8), and RGB_blue ROIs. It will then restrict the
% fibers to those that also pass through the RGB_blue ROIs. 
%
% There are separate loops for Y1 and Y2, using RGB rois from Y1. 

% Directories
baseDir1 = 'Y:\data\reading_longitude\dti'; % year 1 dti directory
baseDir2 = 'Y:\data\reading_longitude\dti_y2'; % year 2
f1 = {'ad040522','ajs040629','at040918','cp041009','crb040707',...
      'ctb040706','ctr040618','da040701','dh040607','dm040922','js040726',...
      'jt040717','lg041019','lj040527','mb041004','md040714','mh040630',...
      'mho040625','mm040925','pf040608','rh040630','sl040609','ss040804',...
      'sy040706','tv040928','vh040719'}; % y1 subject list
f2 = {'ad050604','ajs050621','at051008','cp051008','crb050603',...
      'ctb050603','ctr050528','da050623','dh050513','dm051009','js050611',...
      'jt050618','lg051008','lj050604','mb051014','md050621','mh050514',...
      'mho050528','mm051014','pf050514','rh050514','sl050516','ss081205',...
      'sy050604','tv051004','vh050624'}; % y2 subject list

% Parameters -- not sure if I need them, but just in case
opts.stepSizeMm = 1; % all opts are for tracking
opts.faThresh = 0.2;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.334 0.667];
distanceFromRoi = 0.87; % intersection parameter, minimum value because already dilated

%Y1 loop
for(ii=1:length(f1))
    fname = fullfile(baseDir1, f1{ii}, [f1{ii} '_dt6.mat']); %concatenates stuff in braket into one string, commas add slashes to create a valid path
    disp(['Processing ' fname '...']); %displays a string on the screen
    if exist(fname,'file')
        dt = load(fname); % this will load the dt6 file; you can doublechecheck by typing 'dt.dt6' and it will be a 3-D matrix + 1 more with 6 in it for the six diffusion directions
        %ROIs: load ROIs and create OTS folder
        roiName = {'LOTS_RGB_blue', 'ROTS_RGB_blue'}; %curly brackets are good for lists of strings ROI name list
        roiPath = fullfile(fileparts(fname), 'ROIs', 'OTSproject');
        fiberName = {'LOTS_sphere8', 'ROTS_sphere8'};
        fiberPath = fullfile(fileparts(fname), 'fibers', 'OTSproject');

        for (jj=1:length(roiName))
            roiFileName = fullfile(roiPath,[roiName{jj} '.mat']);
            fiberFileName = fullfile(fiberPath,[fiberName{jj} '.mat']);
            if exist(roiFileName,'file') & exist(fiberFileName,'file')
                % load RGB roi
                roi = dtiReadRoi(roiFileName); % this should not have empty 'coords' field
                % load 30mm restricted to 8mm fibers
                fg = dtiReadFibers(fiberFileName);
                % intersect fibers with ROI
                fgRestricted = dtiIntersectFibersWithRoi(0, 'and', distanceFromRoi, roi, fg, inv(dt.xformToAcPc));
                % save new fiber group
                fgRestricted.name = [fg.name '_AND_RGB_FG'];
                dtiWriteFiberGroup(fgRestricted, fullfile(fiberPath, [fgRestricted.name '.mat']));
            end
        end
    end
end

%Y2 loop
for(ii=1:length(f2))
    fname = fullfile(baseDir2, f2{ii}, [f2{ii} '_dt6_noMask.mat']); %concatenates stuff in braket into one string, commas add slashes to create a valid path
    disp(['Processing ' fname '...']); %displays a string on the screen
    if exist(fname,'file')
        dt = load(fname); % this will load the dt6 file; you can doublechecheck by typing 'dt.dt6' and it will be a 3-D matrix + 1 more with 6 in it for the six diffusion directions
        %ROIs: load ROIs and create OTS folder
        roiName = {'LOTS_RGB_blue', 'ROTS_RGB_blue'}; %curly brackets are good for lists of strings ROI name list
        roiPath = fullfile(baseDir1, f1{ii}, 'ROIs', 'OTSproject'); % get ROIs from Y1 directory
        fiberName = {'LOTS_sphere8', 'ROTS_sphere8'};
        fiberPath = fullfile(fileparts(fname), 'fibers', 'OTSproject');

        for (jj=1:length(roiName))
            roiFileName = fullfile(roiPath,[roiName{jj} '.mat']);
            fiberFileName = fullfile(fiberPath,[fiberName{jj} '.mat']);
            if exist(roiFileName,'file') & exist(fiberFileName,'file')
                % load RGB roi
                roi = dtiReadRoi(roiFileName); % this should not have empty 'coords' field
                % load 30mm restricted to 8mm fibers
                fg = dtiReadFibers(fiberFileName);
                % intersect fibers with ROI
                fgRestricted = dtiIntersectFibersWithRoi(0, 'and', distanceFromRoi, roi, fg, inv(dt.xformToAcPc));
                % save new fiber group
                fgRestricted.name = [fg.name '_AND_RGB_FG'];
                dtiWriteFiberGroup(fgRestricted, fullfile(fiberPath, [fgRestricted.name '.mat']));
            end
        end
    end
end