function dti_FFA_trackHemisphere(intersectflag)

% Usage: dti_FFA_trackHemisphere(default=0)
%
% By: DY 2008/04/09
%
% This script will go through a list of subjects, create whole hemisphere
% ROIs (rectangles), track from those ROIs, and save the fibers. 
%
% If the INTERSECTFLAG is 0, no further action is taken. If 1, then load
% a sphere ROI (FFA) and restrict to endpoints within that ROI. 
%
% History:
% 2008/05/05 DY: will check to see if ROI/FG directories already exist
% 2008/07/27 DY: will loop through everyone in DTI directory and skip
% people who already have LH_rect_FG.mat. 


% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\';
%     dtiDir = 'S:\reading_longitude'; % Use for wandell lab data
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/';
end
%cd(dtiDir); s = dir('*0*');  subs={s.name};

%Hack for Capgras
dtiDir='/biac1/kgs/projects/Capgras/';
cd(dtiDir); s = dir('*dti*'); subs={s.name};

% Default value for intersectflag
if ~exist('intersectflag','var')
    intersectflag=0;
end

% Hemisphere rectangle coordinates
leftx=[-100 0];
rightx=[0 100];
y=[-120 80];
z=[-40 80];
lhname='LH_rect';
rhname='RH_rect';
l_intersectroi='LFFA_disk10.mat';
r_intersectroi='RFFA_disk10.mat';
smoothKernel = 8; % for dilating


% Loops through each of the to-do directories
for ii=1:length(subs)
    thisDir = fullfile(dtiDir,subs{ii},'dti30');
    fname = fullfile(thisDir,'dt6.mat');
    disp(['\nProcessing ' fname '...\n']); %displays a string on the screen
    
    % If fibers don't exist but dt6 does, track. If they do, skip to next subject.
    if ~exist(fullfile(thisDir,'fibers','functional','LH_rect_FG.mat')) & exist(fname)
        
        dt = dtiLoadDt6(fname); % this will load the dt6 file

        % Create fiber directory if it doesn't exist
        fiberDir = fullfile(thisDir,'fibers','functional');
        if (~isdir(fiberDir))
            mkdir(fiberDir);
        end

        % Create roi directory if it doesn't exist
        theroiDir = fullfile(thisDir,'ROIs','functional');
        if (~isdir(theroiDir))
            mkdir(theroiDir);
        end

        % Tracking parameters
        opts.stepSizeMm = 1; % all opts are for tracking
        opts.faThresh = 0.15; % to match default tracking parameters for GUI
        opts.lengthThreshMm = 20;
        opts.angleThresh = 30;
        opts.wPuncture = 0.2;
        opts.whichAlgorithm = 1;
        opts.whichInterp = 1;
        opts.seedVoxelOffsets = [0.25 0.75];
        % DO NOT USE 0.33/0.67 if you want your
        % seeds laid down on a uniform grid.
        distanceFromRoi = 0.87; % default intersection parameter = distance to the
        % corner of a cube of size 1mm because ROI coords are treated as points in
        % the center of a unit cube = sqrt(.5^2*3)

        % BUILD LH and RH rectangle ROIs
        if ~exist(fullfile(theroiDir,[lhname '.mat']))
            lhroi = dtiNewRoi(lhname,'r');
            [X,Y,Z] = meshgrid([leftx(1):leftx(2)],[y(1):y(2)],[z(1):z(2)]);
            lhroi.coords = [X(:), Y(:), Z(:)];
            dtiWriteRoi(lhroi, fullfile(theroiDir, [lhroi.name '.mat'])); % save sphere ROI
        else
            lhroi = dtiReadROI(fullfile(theroiDir,[lhname '.mat']));
        end

        if ~exist(fullfile(theroiDir,[rhname '.mat']))
            rhroi = dtiNewRoi(rhname,'r');
            [X,Y,Z] = meshgrid([rightx(1):rightx(2)],[y(1):y(2)],[z(1):z(2)]);
            rhroi.coords = [X(:), Y(:), Z(:)];
            dtiWriteRoi(rhroi, fullfile(theroiDir, [rhroi.name '.mat'])); % save sphere ROI
        else
            rhroi = dtiReadROI(fullfile(theroiDir,[rhname '.mat']));
        end

        % Track from LH and RH rectangle ROIs
        if ~exist(fullfile(fiberDir,[lhname '_FG.mat']))
            lhfg = dtiFiberTrack(dt.dt6, lhroi.coords, dt.mmPerVoxel, dt.xformToAcpc, [lhroi.name '_FG'],opts);
            dtiWriteFiberGroup(lhfg, fullfile(fiberDir, [lhfg.name '.mat'])); % saves fiber group
        else
            fprintf('Loading LH_rect_FG.mat\n');
            lhfg = dtiReadFibers(fullfile(fiberDir,[lhname '_FG.mat']));
        end

        if ~exist(fullfile(fiberDir,[rhname '_FG.mat']))
            rhfg = dtiFiberTrack(dt.dt6, rhroi.coords, dt.mmPerVoxel, dt.xformToAcpc, [rhroi.name '_FG'],opts);
            dtiWriteFiberGroup(rhfg, fullfile(fiberDir, [rhfg.name '.mat'])); % saves fiber group
        else
            fprintf('Loading RH_rect_FG.mat\n');
            rhfg = dtiReadFibers(fullfile(fiberDir,[rhname '_FG.mat']));
        end

        fprintf('Right before intersection stage...\n');
        if intersectflag
            % Intersect hemisphere fibers with FFA ROI
            fprintf('...Now entering intersection stage\n');
            if exist(fullfile(theroiDir,l_intersectroi))
                lffa = dtiReadRoi(fullfile(theroiDir,l_intersectroi));
                %dilate ROI & save
                lffa = dtiRoiClean(lffa, smoothKernel, {'dilate'});
                lffa.name = 'LFFA_disk10_d8.mat';
                dtiWriteRoi(lffa, fullfile(theroiDir, lffa.name));
                lhfgffa = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, distanceFromRoi, lffa, lhfg);
                lhfgffa.name = ['LH+' lffa.name '.mat']; % save the fiber group
                dtiWriteFiberGroup(lhfgffa, fullfile(fiberDir,lhfgffa.name));
                fprintf('Saved %s',lhfgffa.name);
            else
                fprintf('LFFA ROI not found\n');
            end

            if exist(fullfile(theroiDir,r_intersectroi))
                rffa = dtiReadRoi(fullfile(theroiDir,r_intersectroi));
                %dilate ROI & save
                rffa = dtiRoiClean(rffa, smoothKernel, {'dilate'});
                rffa.name = 'RFFA_disk10_d8.mat';
                dtiWriteRoi(rffa, fullfile(theroiDir, rffa.name));
                rhfgffa = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, distanceFromRoi, rffa, rhfg);
                rhfgffa.name = ['RH+' rffa.name '.mat']; % save the fiber group
                dtiWriteFiberGroup(rhfgffa, fullfile(fiberDir,rhfgffa.name));
                fprintf('Saved %s',rhfgffa.name);
            else
                fprintf('RFFA ROI not found\n');
            end

            clear lhfg rhfg lffa rffa
        else
            fprintf('...Now skipping intersection stage\n');

        end
    end
    disp(['Skipping ' fname ', fibers already exist...\n']); %display
end
