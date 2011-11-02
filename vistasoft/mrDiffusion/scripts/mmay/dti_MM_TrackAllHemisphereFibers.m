% 
%
% This script can be used to track all fibers in each hemisphere of a selected group of subjects 
% (subs) in a given directory (baseDir) and intersect those fibers with the corpus callosum. 
% 
% The script assumes that you have the file structure given by running
% dtiRawPreprocess--- i.e., subDir -> dti(dirs) -> fibers
%
% Edit this script to set the base directory, provide a list of the subject's directories, and set the
% number of directions (e.g., 06, or 40). 
% Tracking parameters can also be adjusted within.
%
% 05/05/2008: R.F.D wrote it.
% 05/08/2008: L.M.P wrote the loop and added the ability to process
% multiple subjects through multiple years. Also added multiple display strings to keep the user
% updated on the status of the tracking. 
% 07/03/2008: L.M.P. added the function dtiWriteFibersPdb to write the groups in
% .pdb format recognized by CINCH.
% 07/22/2008: L.M.P. added the fileFormat flag to determine which format the
% fiber groups should be written as [0=.m, 1=.pdb] 
%


%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_adults'};
dirs = 'dti06'; 
% subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','ct060309','db061209','dl070825','dla050311',...
%    'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
%    'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};
 subs = {'aab050307'};
% subs = {'bw040922'};

fileFormat = 0; % 0 for .m, 1 for .pdb

%% Tracking Parameters
    faThresh = 0.35;
    opts.stepSizeMm = 1;
    opts.faThresh = 0.15;
    opts.lengthThreshMm = [50 250]; 
    opts.angleThresh = 60;
    opts.wPuncture = 0.2;
    opts.whichAlgorithm = 1;
    opts.whichInterp = 1;
    opts.seedVoxelOffsets = [0.25 0.75];


%% Loops through subs and tracks fibers

for ii=1:length(subs)
    for jj=1:length(yr)
        subDir = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        subDir = fullfile(baseDir,yr{jj},subDir.name);
        dt6Dir = fullfile(subDir, dirs);
        fiberDir = fullfile(dt6Dir,'fibers');
        roiDir = fullfile(dt6Dir,'ROIs');
        mRoiDir = fullfile(roiDir,'Mori_Contrack');

        % Load Files and Create ROIs
        disp(['Processing ' subDir '...']);

        % leftOccRoi = dtiRoiClean(dtiReadRoi(fullfile(mRoiDir,'Mori_Occ_CC_100k_top1000_LEFT_fiberROI.mat')), 3, {'fillHoles','removeSatellites'});
        % rightOccRoi = dtiRoiClean(dtiReadRoi(fullfile(mRoiDir,'Mori_Occ_CC_100k_top1000_RIGHT_fiberROI.mat')), 3, {'fillHoles','removeSatellites'});
        
        leftFg = fullfile(fiberDir, 'LFG+Mori_Occ_CC_100k_top1000_LEFT_fiberROI.mat');
        rightFg = fullfile(fiberDir, 'RFG+Mori_Occ_CC_100k_top1000_RIGHT_fiberROI.mat');
        
        cc = dtiReadRoi(fullfile(roiDir,'CC.mat'));
        cc = dtiRoiClean(cc, 3, {'fillHoles','dilate'});
        
        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
        fa = dtiComputeFA(dt.dt6);
        fa(fa>1) = 1; fa(fa<0) = 0;
        roiAll = dtiNewRoi('all');
        mask = fa>=faThresh;
        [x,y,z] = ind2sub(size(mask), find(mask));
        roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);
        
        % LEFT ROI
        roiLeft = dtiRoiClip(roiAll, [0 80]);

        % RIGHT ROI
        roiRight = dtiRoiClip(roiAll, [-80 0]);

        clear roiAll;

        % Track Fibers
        disp('Tracking Left Hemisphere Fibers ...');

        % LEFT hemisphere
%         fg = dtiFiberTrack(dt.dt6,roiLeft.coords,dt.mmPerVoxel,dt.xformToAcpc,'LFG',opts);
        fg = dtiReadFibers(leftFg);
        fg = dtiIntersectFibersWithRoi([], {'not'}, [], cc, fg);
        fg = dtiCleanFibers(fg);
        fg.colorRgb = [20 20 255];
        fg.name = 'LFG+Mori_Occ_CC_100k_top1000_LEFT_fiberROI_notRight';
        if(fileFormat == 0)
            dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
        end
        if(fileFormat == 1)
            dtiWriteFibersPdb(fg,dt.xformToAcpc,dt.mmPerVoxel,fullfile(fiberDir,fg.name));
        end

        disp('...');
        disp(['The fiber group ' fg.name ' has been written to ' fiberDir]);
        disp('...');
        disp('Tracking Right Hemisphere Fibers ...');

        % RIGHT hemisphere
%         fg = dtiFiberTrack(dt.dt6,roiRight.coords,dt.mmPerVoxel,dt.xformToAcpc,'RFG',opts);
        fg = dtiReadFibers(rightFg);
        fg = dtiIntersectFibersWithRoi([], {'not'}, [], cc, fg);
        fg = dtiCleanFibers(fg);
        fg.colorRgb = [255 20 20];
        fg.name = 'RFG+Mori_Occ_CC_100k_top1000_RIGHT_fiberROI_notLeft';
        if(fileFormat == 0)
            dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name));
        end
        if(fileFormat == 1)
            dtiWriteFibersPdb(fg,dt.xformToAcpc,dt.mmPerVoxel,fullfile(fiberDir,fg.name));
        end

        disp('...');
        disp(['The fiber group ' fg.name ' has been written to ' fiberDir]);
        disp('...');

        clear fg;


    end
end

disp('*************');
disp('  DONE!');

%%









