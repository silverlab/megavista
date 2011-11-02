% dti_STS_computeFiberProperties
% 
% This script is used for the analysis of callosum fiber groups. It returns
% fiber values in a tab delimited text file that can be read into
% excel. 
% 
% Values returned include:
% avgFA avgMD avgRD avgAD avgLength minLength maxLength vol ratio numFibers
% 
% VOLUME ESTIMATES:  Volume calculations recquire a t1 file. This script
% assumes that your t1 file is in: baseDir/subs{ii}/t1/t1.nii.gz
% 
% FIBER CLIPPING:  Fiber groups can be clipped so that only a certain
% number of points (nPts) on each side of the midSagital plane are used for
% analysis. This option is turned on or off with the value of 'clip'
% (1=yes, 0=no). It may be informative to run this script twice, once with
% each option to see how the values vary as you consider points across the
% fiber... clipHemi: The default is to clip both left and right sides
% (clipHemi='both'). If clipHemi=='left' then only the left side (i.e.
% fiber coords X < 0) is clipped. Alternately, you can ask for just the
% right side (X>0) to be clipped. This is important if you have fibers that
% were generated such that only one side of the midPlane has fiber points.
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
% HISTORY: 
% 10.09.09 - LMP wrote the thing.
% 11.05.09 - Fixed dtiFiberMidSagSegment function.
% 


%% Set Directory Structure, FiberGroups and Options

baseDir = '/biac3/wandell4/data/reading_longitude/dti_y3/';
subs = {'at0','js0','md0','mh0','mho0','mm0','rh0','ss0'};


dirs = 'dti06trilinrt';
logDir = '/biac3/wandell4/data/reading_longitude/STS_Project';
fileList = '/biac3/wandell4/data/reading_longitude/STS_Project/STS_MNI_Tal_fiberNames.txt';

fiberName = textread(fileList, '%s'); fprintf('\nWill process %d subjects...\n\n',numel(subs));
fiberName2 = {''}; 

merge = 0;      % (1=yes, 0=no)
saveMerged = 0; % (0=no, 1=.pdb, 2=.mat)
clip = 1;       % (1=yes, 0=no)
clipHemi = 'l'; % ('l'= clip only left fiber coords, 'r'= clip only right, 'b' = clip both)
nPts = 10;      % Number of points to keep on each side of midSagitalPlane
saveRoi = 1;    % (1=yes, 0=no)


%% Set up the text file that will store the fiber vals.

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
textFileName = fullfile(logDir,['FiberGroupStats_STS_CC_TemporalSTT',dateAndTime,'.txt']);
textFileNameEr = fullfile(logDir,['FiberGroupStats_STS_CC_ERROR_TemporalSTT',dateAndTime,'.txt']);
      
[fid1 message] = fopen(textFileName, 'w');
fprintf(fid1, 'Subject Code \t Fiber Name \t Mean FA \t Mean MD \t Mean Radial ADC \t Mean Axial ADC \t Number of Fibers (arb) \t Mean Length \t Min Length \t Max Length \t midCC ROI Vol (mm^3) \t Fiber ROI Vol on CC (mm^3) \t Ratio (fiberVol/ccVol) \n');
[fid2 message] = fopen(textFileNameEr, 'w');


%% Run the fiber properties functions 
mergeFlag = 1;

for ii=1:numel(subs)
    sub = dir(fullfile(baseDir,[subs{ii} '*']));
    if ~isempty(sub)
        subDir = fullfile(baseDir,sub.name);
        dt6Dir = fullfile(subDir,dirs);
        fiberDir = fullfile(dt6Dir,'fibers','conTrack'); % Removed ConTrack
        roiDir = fullfile(dt6Dir,'ROIs');

        t1 = readFileNifti(fullfile(subDir,'t1','t1.nii.gz'));
        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));

        disp(['Processing ' subDir '...']);

        % Get the volume of the midCC roi(and save, if it does not exist).
        clippedCC = fullfile(roiDir, 'CC_clipMid.mat');
        if ~exist(clippedCC,'file')
            disp('Clipping ccROI')
            origCC = dtiReadRoi(fullfile(roiDir,'CC.mat'));
            [centerCC roiNot] = dtiRoiClip(origCC, [1 1], [], []);
            [newCC roiNot] = dtiRoiClip(centerCC, [-1 -1], [], []);
            newCC.name = 'CC_clipMid';
            newCC.color = 'g';
            dtiWriteRoi(newCC, clippedCC);
        else
            newCC = dtiReadRoi(clippedCC);
        end
        v = dtiGetRoiVolume(newCC,t1,dt);
        ccVol = v.volume;

        % Read in fiber groups
        for kk=1:numel(fiberName)
try
            fiberGroup = fullfile(fiberDir, fiberName{kk});
            if merge == 1, 
                fiberGroup2 = fullfile(fiberDir, fiberName2{kk}); 
            end         
            
            % If one fiber group does not exist in the merge case we will
            % set fiberGroup = to fiberGroup2 if that does exist (eg, RLatFront)
            if ~exist(fiberGroup,'file') && merge == 1 && exist(fiberGroup2,'file')
                fiberGroup = fiberGroup2;
                mergeFlag = 0;
            end
            
            % If a fiber group does not exist for a given subject (eg, latFront) we will skip it and move on.
            if exist(fiberGroup,'file')
                disp(['Computing Fiber Properties for ' fiberGroup ' ...']);
                try fg = dtiReadFibers(fiberGroup);
                catch ME
                    fg = mtrImportFibers(fiberGroup); 
                end

                % Merge fiber groups.
                if merge == 1 
                    if exist(fiberGroup2,'file') && mergeFlag ~= 0
                        if numel(fiberName) ~= numel(fiberName2), error('To merge fiber groups you must have an equal number in fiberName and fiberName2.'); end
                        disp(['Merging ' fiberName{kk} ' and ' fiberName2{kk}]);
                        try fg2 = dtiReadFibers(fiberGroup2);
                        catch ME, fg2 = mtrImportFibers(fiberGroup2); end

                        fg = dtiMergeFiberGroups(fg,fg2);

                        if(saveMerged >0), disp(['Saving ' fg.name ' to ' fiberDir]);
                            if(saveMerged == 1), dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,fg.name)); end
                            if(saveMerged == 2), dtiWriteFiberGroup(fg,fullfile(fiberDir,fg.name)); end
                        else disp('Not Saving Merged Fiber Group...');
                        end
                    else disp(['We cannot merge ' fiberName{kk} ' & ' fiberName2{kk} '. Computing values of 1 group: ' fg.name]);
                    end
                end

                % Clip fiber groups.
                if clip == 1
                    disp('Clipping fiber group...');
                    fg = dtiFiberMidSagSegment(fg,nPts,clipHemi);
                    
                    % Create ROI and clip to only include the midSagitalPlane (1mm)
                    roi = dtiCreateRoiFromFibers(fg);
                    try [newCC roiNot] = dtiRoiClip(roi, [1 80], [], []); catch end
                    try [newCC roiNot] = dtiRoiClip(newCC, [-80 -1], [], []); catch end
                    roi = newCC;
                    roi.name = [fg.name '_CCroi'];
                    roi.color = 'y';
                    if(saveRoi == 1), dtiWriteRoi(roi,fullfile(roiDir,roi.name)); end
                    rv = dtiGetRoiVolume(roi,t1,dt);
                    roiVol = rv.volume;
                else
                    disp('Not clipping fiber group ...');
                    % Clip fiber group from which we'll create the ROI. We
                    % won't use this fiber group for any other analysis.
                    fgTemp = dtiFiberMidSagSegment(fg,nPts,clipHemi);l  

                    % Create ROI and clip to only include the midSagitalPlane (1mm)
                    roi = dtiCreateRoiFromFibers(fgTemp);
                    try [newCC roiNot] = dtiRoiClip(roi, [1 80], [], []); catch end
                    try [newCC roiNot] = dtiRoiClip(newCC, [-80 -1], [], []); catch end
                    roi = newCC;
                    roi.name = [fg.name '_CCroi'];
                    roi.color = 'y';
                    if saveRoi == 1, dtiWriteRoi(roi,fullfile(roiDir,roi.name)); end
                    rv = dtiGetRoiVolume(roi,t1,dt);
                    roiVol = rv.volume;
                    clear fgTemp
                end

                %% Compute the fiber statistics
                coords = horzcat(fg.fibers{:})';
                numberOfFibers=numel(fg.fibers);

                % Measure the step size of the first fiber. They *should*
                % all be the same! ** This does not work if the cell is empty!
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

                % We now have the dt6 data from all of the fibers.  We extract the
                % directions into vec and the eigenvalues into val.  The units of val are
                % um^2/sec or um^2/msec ... somebody answer this here, please.
                [vec,val] = dtiEig(dt6);

                % Tragically, some of the ellipsoid fits are wrong and we get negative eigenvalues.
                % These are annoying. If they are just a little less than 0, then clipping
                % to 0 is not an entirely unreasonable thing. Maybe we should check for the
                % magnitude of the error?
                nonPD = find(any(val<0,2));
                if(~isempty(nonPD))
                    fprintf('\n NOTE: %d fiber points had negative eigenvalues. These will be clipped to 0...\n',numel(nonPD));
                    val(val<0) = 0;
                end

                threeZeroVals=find(sum(val, 2)==0);
                if ~isempty (threeZeroVals)
                    fprintf('\n NOTE: %d of these fiber points had all three negative eigenvalues. These will be excluded from analyses\n', length(threeZeroVals));
                end

                val(threeZeroVals, :)=[];

                % Now we have the eigenvalues just from the relevant fiber positions - but
                % all of them.  So we compute for every single node on the fibers, not just
                % the unique nodes.
                [fa,md,rd,ad] = dtiComputeFA(val);

                %Some voxels have all the three eigenvalues equal to zero (some of them
                %probably because they were originally negative, and were forced to zero).
                %These voxels will produce a NaN FA
                FA(1)=min(fa(~isnan(fa))); FA(2)=mean(fa(~isnan(fa))); FA(3)=max(fa(~isnan(fa))); % isnan is needed because sometimes if all the three eigenvalues are negative, the FA becomes NaN. These voxels are noisy.
                MD(1)=min(md); MD(2)=mean(md); MD(3)=max(md);
                radialADC(1)=min(rd); radialADC(2)=mean(rd); radialADC(3)=max(rd);
                axialADC(1)=min(ad); axialADC(2)=mean(ad); axialADC(3)=max(ad);
                length(1) = mean(fiberLength)*stepSize; length(2) = min(fiberLength)*stepSize; length(3) = max(fiberLength)*stepSize;

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
                clear fg val val1 val2 val3 val4 val5 val6 vec md rd
            else disp(['Fiber group: ' fiberGroup ' not found. Skipping...'])
            end
catch ME  
    disp(['ERROR: ' ME.message ' Skipping ' fg.name]);
    fprintf(fid2,'%s \t %s\n', fiberGroup, ME.message);
   
end
        end       
    else disp('No data found.');
    end
end
% save the stats file.
fclose(fid1);
fclose(fid2);

disp('DONE!');
return


%% Code snippets
% Loop over newFg.fibers and remove any cell that is empty. Create a new
% % cell array void of the empty cells and save that as the .fibers cell array.
% fiberNum = 0;
% c = 0;
% for kk=1:numel(newFg.fibers)
%     if ~isempty(newFg.fibers{kk})
%         fiberNum = (fiberNum+1);
%         temp.fibers{fiberNum} = newFg.fibers{kk};
%     else
%         c = (c+1);
%     end
% end
% newFg.fibers = temp.fibers;
% 
% disp([num2str(c) ' fibers were excluded because they did not meet requirements and were empty']);
