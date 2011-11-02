function dti_FFA_makeSpheres(dt,theROI,roiNames,endptradius,trackradius,roiDir,fiberDir,intersectList,intersectradius)

% Usage:
% dti_FFA_makeSpheres(dt,theROI,roiNames,endptradius,trackradius,roiDir,fiberDir,[intersectList],[intersectradius])
%
% dt = a struct resulting from dtiLoadDt6(dt6.mat)
% theROI = full path to ROI file
% roiNames = cell array of filename prefixes
% endptradius = radius of small sphere restrict to endpoints (mm)
% trackradius = will track from center of sphere of this radius (mm)
% roiDir = full path to where ROIs should be saved
% fiberDir = full path to where fibers should be saved
%
% OPTIONAL: if you want to intersect these fibers with sphere centered
% around other functional ROIS, define last two arguments
% [intersectList] = cell array of ROIs to intersect with first ROI (fullpath)
% [intersectradius] = will intersect with sphere of this radius (mm)
%
% This function will load ROIs, grow a 30mm sphere in
% center of the functionally defined ROI, track fibers, restrict to those
% fibers that have endpoints in an 8mm sphere with the same center, and
% save these fibers.
%
% Modification: we should really track fibers for the entire hemisphere
% first (see DTI_FFA_TRACKHEMISPHERES), so now I load these fibers and
% perform all the intersections with various ROIs. Also, in the case that
% I'm running the script for the second time, the script checks to see if
% an ROI exists and if it does, loads it rather than creates it from
% scratch.
%
% Davie 2008/03/31 
% Davie 2008/03/31 Fixed seedVoxelOffsets and faThresh tracking parameters
% Davie 2008/04/10 Modification (see above, track hemisphere, load ROI)
 
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

roi = dtiReadRoi(theROI);
[tmp rname]=fileparts(theROI);
thehemisphere=rname(1);

% FINDS CENTER OF FUNCTIONAL ROI AND BUILDS A SMALL SPHERE ROI, UNLESS THE
% FILE ALREADY EXISTS
smallName = [roiNames{1} '_sphere' num2str(endptradius, '%01d')];
if ~exist([smallName '.mat'],'file')
    smallSphere = dtiNewRoi(smallName, 'r');
    centerCoord = round(mean(roi.coords,1)*10)/10; % finds center of ROI
    smallSphere.coords = dtiBuildSphereCoords(centerCoord, endptradius); % builds sphere of radius 30
    dtiWriteRoi(smallSphere, fullfile(roiDir, [smallSphere.name '.mat'])); % save sphere ROI
else
    smallSphere=dtiReadRoi([smallName '.mat']);
end

% % FINDS CENTER OF FUNCTIONAL ROI AND BUILDS A 30MM SPHERE ROI
% sphereName = [roiNames{1} '_sphere' num2str(trackradius, '%02d')];
% bigSphere = dtiNewRoi(sphereName, 'r'); %sphereName is in the .name field, see dtiNewRoi for more details
% centerCoord = round(mean(roi.coords,1)*10)/10; % finds center of ROI
% bigSphere.coords = dtiBuildSphereCoords(centerCoord, trackradius); % builds sphere of radius 30
% dtiWriteRoi(bigSphere, fullfile(roiDir, [bigSphere.name '.mat'])); % save sphere ROI
% % TRACKS FIBERS FROM 30MM SPHERE
% fgSphere = dtiFiberTrack(dt.dt6, bigSphere.coords, dt.mmPerVoxel, dt.xformToAcpc, [bigSphere.name '_FG'],opts);
% dtiWriteFiberGroup(fgSphere, fullfile(fiberDir, [fgSphere.name '.mat'])); % saves fiber group
%intersect BY ENDPTS fiber group with small sphere roi

if isequal(lower(thehemisphere),'l')
    fprintf('Loading LH_rect_FG.mat\n');
    fgSphere = dtiReadFibers(fullfile(fiberDir,'LH_rect_FG.mat'));
elseif isequal(lower(thehemisphere),'r')
    fprintf('Loading RH_rect_FG.mat\n');
    fgSphere = dtiReadFibers(fullfile(fiberDir,'RH_rect_FG.mat'));
end

fgRestricted = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, distanceFromRoi, smallSphere, fgSphere);
fgRestricted.name = smallSphere.name; % save the fiber group
dtiWriteFiberGroup(fgRestricted, fullfile(fiberDir, [fgRestricted.name '.mat']));

% If there are intersecting ROIs provided, 
if(exist('intersectList','var') && exist('intersectradius','var'))
    for ii=1:length(intersectList)
        if(exist(intersectList{ii},'file'))
            roi = dtiReadRoi(intersectList{ii});
            intersectName = [roiNames{ii+1} '_sphere' num2str(intersectradius, '%01d')];
            if ~exist([intersectName '.mat'],'file')
                intersectSphere = dtiNewRoi(intersectName, 'r');
                centerCoord = round(mean(roi.coords,1)*10)/10; % finds center of ROI
                intersectSphere.coords = dtiBuildSphereCoords(centerCoord, intersectradius);
                dtiWriteRoi(intersectSphere, fullfile(roiDir, [intersectSphere.name '.mat'])); % save sphere ROI
            else
                intersectSphere=dtiReadRoi([intersectName '.mat']);
            end
            
            % Once without endpoints
            fgIntersect=dtiIntersectFibersWithRoi(0,{'and'},distanceFromRoi,intersectSphere,fgRestricted);
            fgIntersect.name = [fgRestricted.name '+' intersectName];
            dtiWriteFiberGroup(fgIntersect, fullfile(fiberDir, [fgIntersect.name '.mat']));
            % Once with endpoints
            fgIntersectEndpts=dtiIntersectFibersWithRoi(0,{'and','endpoints'},distanceFromRoi,intersectSphere,fgRestricted);
            fgIntersectEndpts.name = [fgRestricted.name '+' intersectName '_endpts'];
            dtiWriteFiberGroup(fgIntersectEndpts, fullfile(fiberDir, [fgIntersectEndpts.name '.mat']));
        end
    end
end

return