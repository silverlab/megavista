% dti_FINRA_TrackFibers
%


%% directory structure
baseDir = '/home/lmperry/Desktop/';
dirs = 'dti40'; % This is the folder that contains the dt6.mat file. Named for # of dirs.

ROI1 = {'vta','vta','rnacc','lnacc','rthal','lthal'};    
ROI2 = {'rnacc','lnacc','rthal','lthal','rmpfc','lmpfc'};

subs = {'FINRA_AP'}; 

fileFormat = 1; % 0 for .m, 1 for .pdb


%% Tracking Parameters

faThresh = 0.35;
opts.stepSizeMm = 1;
opts.faThresh = 0.25;%0.15;
opts.lengthThreshMm = [20 250];
opts.angleThresh = 60;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [.25]; % .5 [-.25 .25]


%% Loops through subs and tracks fibers

for ii=1:length(subs)

    sDir = dir(fullfile(baseDir,[subs{ii} '*']));
    subDir = fullfile(baseDir,sDir.name);
    dt6Dir = fullfile(subDir, dirs); % Will have to change this to add DTI
    fiberDir = fullfile(dt6Dir,'fibers');
    roiDir = fullfile(subDir,'dti_rois');

    fprintf('Processing %s\n', subDir);

    dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
    fa = dtiComputeFA(dt.dt6);
    fa(fa>1) = 1; fa(fa<0) = 0;

    roiAll = dtiNewRoi('all');
    mask = fa>=faThresh;
    [x,y,z] = ind2sub(size(mask), find(mask));
    roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);
    
    if exist(fullfile(fiberDir,'AllFG.pdb'),'file')
        fg = mtrImportFibers(fullfile(fiberDir,'AllFG.pdb'));
    else
        fg = dtiFiberTrack(dt.dt6,roiAll.coords,dt.mmPerVoxel,dt.xformToAcpc,'AllFG',opts);
        dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name));
    end

    %% Intersect ROIs and save out the fiber groups
    for kk=1:numel(ROI1)
        r1 = dtiReadRoi(fullfile(roiDir,[ROI1{kk} '.mat']));
        r1 = dtiRoiClean(r1,[3 3 3],{'fillholes','dilate'});
        r2 = dtiReadRoi(fullfile(roiDir,[ROI2{kk} '.mat']));
        r2 = dtiRoiClean(r2,[3 3 3],{'fillholes','dilate'});
        fgInt = dtiIntersectFibersWithRoi([], {'and'}, [], r1, fg);
        fgInt = dtiIntersectFibersWithRoi([],{'and'},[],r2,fgInt);
        fgInt = dtiCleanFibers(fgInt);
        fgInt.name = ['FG_' ROI1{kk} '_' ROI2{kk}];
        if numel(fgInt.fibers) >= 1
            if(fileFormat == 0)
                dtiWriteFiberGroup(fgInt,fullfile(fiberDir,fgInt.name));
            end
            if(fileFormat == 1)
                dtiWriteFibersPdb(fgInt,dt.xformToAcpc,fullfile(fiberDir,fgInt.name));
            end
            disp('...');
            disp(['The fiber group ' fgInt.name ' has been written to ' fiberDir]);
            disp('...');
        else disp('Fiber group struct is EMPTY! NOT SAVING~')
        end
    end

    clear fg fgInt

end

disp('*************');
disp('  DONE!');










