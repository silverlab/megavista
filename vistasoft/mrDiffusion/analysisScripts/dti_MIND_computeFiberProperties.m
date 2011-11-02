% 
% This script is used for the analysis of callosum fiber groups. It returns
% fiber values in a tab delimited text file that can be read into
% excel. The text file is saved in the baseDirectory by default. 
% 
% Values returned include:
% avgFA avgMD avgRD avgAD avgLength minLength maxLength vol ratio numFibers
%
% VOLUME ESTIMATES:  Volume calculations recquire a t1 file. This script
% assumes that your t1 file is in a directory (alone) with the following file
% structure:
% [...]/[subDirectory]/t1/[t1file].nii.gz
% 
% FIBER CLIPPING:  Fiber groups can be clipped so that only a certain
% number of points (nPts) on each side of the midSagital plane are used for
% analysis. This option is turned on or off with the value of 'clip'
% (1=yes, 0=no). It may be informative to run this script twice, once with
% each option to see how the values vary as you consider points across the
% fiber...
% 
% ROIS:  ROIs are created from the fiber groups and clipped so that only
% the fiber points on the midSagital plane (1mm) contribute to the ROI. The
% volume of this ROI is calculated and reported. These ROIs can be saved if
% the value of 'saveRoi' is set to 1 (1=yes, 0=no). This could be helpful
% to visualize where on the callosum the fibers cross. Right now there is
% no clever way to set the color of the rois, so they're all yellow... An
% ROI is also created and saved from the CC.mat file in the ROIs directory.
% This ROI is only the central 1mm slice of the CC.mat ROI. *Note that this
% script assumes that you have a CC.mat ROI saved in the ROIs folder. The
% volume of this roi will also be computed. The ratio: fiberROI/ccRoi will
% also be calculated and reported as a metric of the area a given fiber
% group covers on the callosum. *Note that because given fiber groups
% overlap after merging, you may have fiber ratios that sum to more than
% 100 percent - not sure if we can get around this, it's a resolution
% problem, as we have more than one fiber per voxel.
% 
% FIBER MERGING:  It may be beneficial to have the segmented fiber groups
% merged, so that we can get one value for each of the segmented groups.
% This is an option set by 'merge' (1=yes, 0=no). ***Important, if you want
% to use merged fiber groups there must be an equal number of fiber groups
% in fiberName and fiberName2*** The first fg in fiberName will be merged
% with the first in fiberName2 and so on... If you wish to save the
% resulting merged fiber groups, set 'saveMerged' to 1 or 2 (1=.pdb,
% 2-.mat). If you're not merging groups, because you wish to analyze them
% seperately, you can leave fiberName2 as an empty cell aray- {} - only the
% fiber groups in fiberName will be analyzed.
% 
% HISTORY: 10.09.09 - LMP wrote the thing.
%          10.20.10 - LMP made multiple changes to deal with the clipping
%                     of fibers coming from .pdb files that do not cross the midline. 
%                     Multiple changes were also made to the organization
%                     of the code. ROI volume estimates are no longer
%                     computed when clip == 0.

%% Set directory structure
baseDir     = '/home/christine/APP/stanford_DTI/';
subCodeList = '/home/christine/APP/stanford_DTI/latfront_complete.txt';
subs        = textread(subCodeList, '%s'); fprintf('\nWill process %d subjects...\n\n',numel(subs));
dirs        = 'dti30trilinrt';   
fibers      = 'fibers';          

%% Set fiber groups
fiberName   = {'Clean_LatFront_Left_top1000.pdb'};
fiberName2  = {'Clean_LatFront_Right_top1000.pdb'}; % **
% **Use fiberName2 only if you want the fiber groups merged, else use only fiberName.

%% Set options - see comments above for info.
merge       = 1;  % (1=yes, 0=no)
saveMerged  = 1;  % (0=no, 1=.pdb, 2=.mat)
clip        = 1;  % (1=yes, 0=no)
nPts        = 10; % Number of points to keep on each side of midSagitalPlane
saveRoi     = 1;  % (1=yes, 0=no) to save ROI on the callosum

%% Set up the text file that will store the fiber vals.
dateAndTime     = getDateAndTime; 
statsFileName   = fullfile(baseDir,['FiberGroupStats_Struct_',dateAndTime,'.mat']);
textFileName    = fullfile(baseDir,['FiberGroupStats_',dateAndTime,'.txt']);     
[fid1 message]  = fopen(textFileName, 'w');
fprintf(fid1, 'Subject Code \t Fiber Name \t Mean FA \t Mean MD \t Mean Radial ADC \t Mean Axial ADC \t Number of Fibers (arb) \t Mean Length \t Min Length \t Max Length \t midCC ROI Vol (mm^3) \t Fiber ROI Vol on CC (mm^3) \t Ratio (fiberVol/ccVol) \n');

%% Run the fiber properties functions 
mergeFlag = 1;
for ii=1:numel(subs)
    sub = dir(fullfile(baseDir,[subs{ii} '*']));
    if ~isempty(sub)
        subDir = fullfile(baseDir,sub.name);
        dt6Dir = fullfile(subDir,dirs);
        fiberDir = fullfile(dt6Dir,fibers,'conTrack');
        roiDir = fullfile(dt6Dir,'ROIs');

        t1File = dir(fullfile(subDir,'t1','*.nii.gz'));
        t1 = readFileNifti(fullfile(subDir,'t1',t1File.name));
        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));

        fprintf('\nProcessing %s\n', subDir);

%% Get the volume of the midCC roi (Create and save, if it does not exist).
        midCC = fullfile(roiDir, 'CC_clipMid.mat');
        if ~exist(midCC,'file') || ~exist(fullfile(roiDir,'CC_clipLeft.mat'),'file')
            disp('Clipping ccROI')
            origCC = fullfile(roiDir,'CC.mat'); % error
            dtiClipCCRoi(origCC,roiDir);
            midCC  = dtiReadRoi(midCC);
        else
            midCC  = dtiReadRoi(midCC);
        end
        v = dtiGetRoiVolume(midCC,t1,dt);
        ccVol = v.volume;

%% Read in fiber groups
        for kk=1:numel(fiberName)
            fiberGroup = fullfile(fiberDir, fiberName{kk});
            if merge == 1 && ~isempty(fiberName2)
                fiberGroup2 = fullfile(fiberDir, fiberName2{kk});
            end
            % If one fiber group does not exist in the merge case we will
            % set fiberGroup to fiberGroup2 if that does exist (eg, RLatFront)
            if ~exist(fiberGroup,'file') && merge == 1 && exist(fiberGroup2,'file')
                fiberGroup = fiberGroup2;
                mergeFlag = 0;
            end

            if exist(fiberGroup,'file')
                disp(['Computing dtiVals for ' fiberGroup ' ...']);
                try fg1 = dtiReadFibers(fiberGroup);
                catch ME
                    fg1 = mtrImportFibers(fiberGroup);
                end

                if clip==0, fg=fg1; end

%% Merge fiber groups without clipping.
                if merge == 1
                    if exist(fiberGroup2,'file') && mergeFlag ~= 0
                        if numel(fiberName) ~= numel(fiberName2), error('To merge fiber groups you must have an equal number in fiberName and fiberName2.'); end
                        disp(['Merging ' fiberName{kk} ' and ' fiberName2{kk}]);
                        try fg2 = dtiReadFibers(fiberGroup2); catch ME, fg2 = mtrImportFibers(fiberGroup2); end

                        fg = dtiMergeFiberGroups(fg1,fg2);
                        fg = dtiNewFiberGroup(fg.name,[],[],[],fg.fibers);

                        if(saveMerged >0) && clip == 0, disp(['Saving ' fg.name ' to ' fiberDir]);
                            if(saveMerged == 1), dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name)); end
                            if(saveMerged == 2), dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name)); end
                        else
                        end
                    else disp(['We cannot merge ' fiberName{kk} ' & ' fiberName2{kk} '. Computing values of 1 group: ' fg.name]);
                    end
                end

%% Clip and merge fiber groups.
                if clip == 1 && merge == 1
                    if mean(fg1.fibers{ii}(1,:)) < 0
                        fprintf('Fiber points indicate left clip is necessary for %s...',fg1.name);
                        fgc = dtiFiberMidSagSegment(fg1,nPts,'l'); % clip the left
                    end
                    if mean(fg1.fibers{ii}(1,:)) > 0
                        fprintf('Fiber points indicate right clip is necessary for %s...',fg1.name);
                        fgc = dtiFiberMidSagSegment(fg1,nPts,'r'); % clip the right
                    end
                    fgA = fgc;
                    % Clip fiber group 2.
                    if mean(fg2.fibers{ii}(1,:)) < 0
                        fprintf('Fiber points indicate left clip is necessary for %s...',fg2.name);
                        fgc = dtiFiberMidSagSegment(fg2,nPts,'l'); % clip the left
                    end
                    if mean(fg2.fibers{ii}(1,:)) > 0
                        fprintf('Fiber points indicate right clip is necessary for %s...',fg2.name);
                        fgc = dtiFiberMidSagSegment(fg2,nPts,'r'); % clip the right
                    end
                    fgB = fgc;

                    disp('Merging fiber groups');
                    fg = dtiMergeFiberGroups(fgA,fgB);
                    % Save merged fibers.
                    if(saveMerged >0), disp(['Saving ' fg.name ' to ' fiberDir]);
                        if(saveMerged == 1), dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name)); end
                        if(saveMerged == 2), dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name)); end
                    else disp('Not Saving Merged Fiber Group...');
                    end
                end

%% Clip fibers without merging or saving
                if clip == 1 && merge == 0
                    fiberCount = numel(fg1.fibers);
                    fgc = dtiFiberMidSagSegment(fg1,nPts);

                    if isempty(fgc.fibers) || numel(fgc.fibers) < (fiberCount-100) && mean(fg1.fibers{ii}(1,:)) < 0
                        fprintf('Fiber points indicate left clip is necessary for %s...',fg1.name);
                        fgc = dtiFiberMidSagSegment(fg1,nPts,'l');
                    end
                    if isempty(fgc.fibers) || numel(fgc.fibers) < (fiberCount-100) && mean(fg2.fibers{ii}(1,:)) > 0
                        fprintf('Fiber points indicate right clip is necessary for %s...',fg1.name);
                        fgc = dtiFiberMidSagSegment(fg1,nPts,'l');
                    end
                    if isempty(fgc.fibers)
                        error('FGC.SEEDS IS EMPTY')
                    else
                        fg = fgc;
                    end
                end

%% Create ROI from clipped fibers and clip the ROI to only include the midSagitalPlane (1mm)
                if clip == 1
                    roi = dtiCreateRoiFromFibers(fg);
                    [centerCC roiNot] = dtiRoiClip(roi, [1 80], [], []);
                    [newCC roiNot] = dtiRoiClip(centerCC, [-80 -1], [], []);
                    roi = newCC;
                    roi.name = [fg.name '_CCroi'];
                    roi.color = 'y';
                    if(saveRoi == 1), dtiWriteRoi(roi,fullfile(roiDir,roi.name)); end
                    rv = dtiGetRoiVolume(roi,t1,dt);
                    roiVol = rv.volume;
                else
                    disp('Not clipping fiber group ...');
                    roiVol = [];
                end

%% Compute the fiber statistics and write them to the text file
                coords = horzcat(fg.fibers{:})';
                numberOfFibers=numel(fg.fibers);

                % Measure the step size of the first fiber. They *should* all be the same!
                stepSize = mean(sqrt(sum(diff(fg.fibers{1},1,2).^2)));
                fiberLength = cellfun('length',fg.fibers);

                % The rest of the computation does not require remembering which node
                % belongd to which fiber.
                [val1,val2,val3,val4,val5,val6] = dtiGetValFromTensors(dt.dt6, coords, inv(dt.xformToAcpc),'dt6','nearest');
                dt6 = [val1,val2,val3,val4,val5,val6];

                % Clean the data in two ways.
                % Some fibers extend a little beyond the brain mask. Remove those points by
                % exploiting the fact that the tensor values out there are exactly zero.
                dt6 = dt6(~all(dt6==0,2),:);

                % There shouldn't be any nans, but let's make sure:
                dt6Nans = any(isnan(dt6),2);
                if(any(dt6Nans))
                    dt6Nans = find(dt6Nans);
                    for jj=1:6
                        dt6(dt6Nans,jj) = 0;
                    end
                    fprintf('\ NOTE: %d fiber points had NaNs. These will be ignored...',length(dt6Nans));
                    disp('Nan points (ac-pc coords):');
                    for jj=1:length(dt6Nans)
                        fprintf('%0.1f, %0.1f, %0.1f\n',coords(dt6Nans(jj),:));
                    end
                end

                % We now have the dt6 data from all of the fibers.  We
                % extract the directions into vec and the eigenvalues into
                % val.  The units of val are um^2/sec or um^2/msec
                % mrDiffusion tries to guess the original units and convert
                % them to um^2/msec. In general, if the eigenvalues are
                % values like 0.5 - 3.0 then they are um^2/msec. If they
                % are more like 500 - 3000, then they are um^2/sec.
                [vec,val] = dtiEig(dt6);

                % Some of the ellipsoid fits are wrong and we get negative eigenvalues.
                % These are annoying. If they are just a little less than 0, then clipping
                % to 0 is not an entirely unreasonable thing. Maybe we should check for the
                % magnitude of the error?
                nonPD = find(any(val<0,2));
                if(~isempty(nonPD))
                    fprintf('\n NOTE: %d fiber points had negative eigenvalues. These will be clipped to 0...\n',numel(nonPD));
                    val(val<0) = 0;
                end

                threeZeroVals=find(sum(val,2)==0);
                if ~isempty (threeZeroVals)
                    fprintf('\n NOTE: %d of these fiber points had all three negative eigenvalues. These will be excluded from analyses\n', length(threeZeroVals));
                end

                val(threeZeroVals,:)=[];

                % Now we have the eigenvalues just from the relevant fiber positions - but
                % all of them.  So we compute for every single node on the fibers, not just
                % the unique nodes.
                [fa,md,rd,ad] = dtiComputeFA(val);

                %Some voxels have all the three eigenvalues equal to zero (some of them
                %probably because they were originally negative, and were forced to zero).
                %These voxels will produce a NaN FA
                FA(1)=min(fa(~isnan(fa)));
                FA(2)=mean(fa(~isnan(fa)));
                FA(3)=max(fa(~isnan(fa))); % isnan is needed because sometimes if all the three eigenvalues are negative, the FA becomes NaN. These voxels are noisy.
                MD(1)=min(md);
                MD(2)=mean(md);
                MD(3)=max(md);
                radialADC(1)=min(rd);
                radialADC(2)=mean(rd);
                radialADC(3)=max(rd);
                axialADC(1)=min(ad);
                axialADC(2)=mean(ad);
                axialADC(3)=max(ad);
                length(1) = mean(fiberLength)*stepSize;
                length(2) = min(fiberLength)*stepSize;
                length(3) = max(fiberLength)*stepSize;

                avgFA = FA(2);
                avgMD = MD(2);
                avgRD = radialADC(2);
                avgAD = axialADC(2);
                avgLength = length(1);
                minLength = length(2);
                maxLength = length(3);
                ratio =(roiVol/ccVol);
                numFibers = numel(fg.fibers);

                % Write out to the the stats file.
                fprintf(fid1,'%s\t %s\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t\n', subs{ii},fg.name,avgFA,avgMD,avgRD,avgAD,numFibers,avgLength,minLength,maxLength,ccVol,roiVol,ratio);

            else disp(['Fiber group: ' fiberGroup ' not found. Skipping...'])
            end
        end
    else disp('No data found.');
    end
end
% save the stats file.
fclose(fid1);

disp('DONE!');
return
