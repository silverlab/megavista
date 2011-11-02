%% Initialize vars and get subject list
%

ccThresh = 0.5;
applyBrainMask = true;
maxFiberLen = 250;
mmBeyond = 10;

nSampsPerFiber = mmBeyond*2+1;

bd = '/biac3/wandell4/data/reading_longitude/';
outDir = fullfile(bd,'callosal_analysis');
checkCCDir = fullfile(outDir,'checkCC');
%dd = {'dti_y1','dti_y2','dti_y3','dti_y4'};
%inDir = {'dti06','dti06','ssdti06','dti06'};
dd = {'dti_y1','dti_y2','dti_y3','dti_y4'};
inDir = {'dti06trilinrt','dti06trilinrt','dti06trilinrt','dti06trilinrt'};
fiberDir = 'dti06trilinrt';
%exclude = {'mb070905_motionBad','ajs060707'};

outFileName = ['ccLongitudinal_segData_090722'];
if(~exist(outDir,'dir')) mkdir(outDir); end
logFileName = fullfile(outDir,['CallosalSegLog_' datestr(now,'yymmdd_HHMM') '.txt']);

logFile = fopen(logFileName,'wt');
s=license('inuse'); userName = s(1).user;
fprintf(logFile, '* * * Analysis run by %s on %s * * *\n', userName, datestr(now,31));
fclose(logFile);

% Gather all the files
n = 0;
for(jj=1:length(dd))
    d = dir(fullfile(bd,dd{jj},'*0*'));
    for(ii=1:length(d))
        if(~exist('exclude','var')||isempty(strmatch(d(ii).name,exclude,'exact')))
            tmp = fullfile(bd,dd{jj},d(ii).name,inDir{jj},'dt6.mat');
            if(exist(tmp,'file'))
                n = n+1;
                datFiles(n).subDir = d(ii).name;
                datFiles(n).dt6 = tmp;
                datFiles(n).datDir = fullfile(bd,dd{jj},d(ii).name,inDir{jj});
                datFiles(n).fiberDir = fullfile(bd,dd{jj},d(ii).name,fiberDir,'fibers');
                datFiles(n).roiDir = fullfile(bd,dd{jj},d(ii).name,fiberDir,'ROIs');
                datFiles(n).sc = strtok(datFiles(n).subDir,'0');
                datFiles(n).year = jj;
                if(datFiles(n).year==1)
                    datFiles(n).moriRoiDir = fullfile(fileparts(datFiles(n).datDir),'ROIs');
                else
                    datFiles(n).moriRoiDir = '';
                end
            end
        end
    end
end
subCodes = {datFiles(:).sc};

for(ii=1:n)
    % We use the CC ROI from the current year.
    % Check for a manually-defined CC ROI and use that if it exists.
    datFiles(ii).ccRoiFname = fullfile(datFiles(ii).roiDir, 'CC_man.mat');
    if(~exist(datFiles(ii).ccRoiFname,'file'))
        datFiles(ii).ccRoiFname = fullfile(datFiles(ii).roiDir, 'CC.mat');
        if(~exist(datFiles(ii).ccRoiFname,'file'))
            datFiles(ii).ccRoiFname = '';
        end
    end

    % But Mori ROIs will be pulled from the first year, so we use the first
    % year ROI dir.
    if(datFiles(ii).year>1)
        % Find all years for this subjects
        allYears = strmatch(datFiles(ii).sc,subCodes,'exact');
        % Get the roiDir from this subject's first year.
        datFiles(ii).moriRoiDir = datFiles(allYears([datFiles(allYears).year]==1)).moriRoiDir;
    end
    fprintf('% 3d: %s\n',ii,datFiles(ii).subDir);
end


if(1)
    %% Track fibers and intersect with CC
    faThresh = 0.35;
    opts.stepSizeMm = 1;
    opts.faThresh = 0.15;
    opts.lengthThreshMm = [50 maxFiberLen];
    opts.angleThresh = 60;
    opts.wPuncture = 0.2;
    opts.whichAlgorithm = 1;
    opts.whichInterp = 1;
    opts.seedVoxelOffsets = [-0.25 0.25];
    opts.offsetJitter = 0;

    for(ii=1:n)
        tic;
        fprintf('Processing %d of %d (%s)...\n',ii,n,datFiles(ii).subDir);
        roiPath = fullfile(datFiles(ii).datDir,'ROIs');
        fgPath = fullfile(datFiles(ii).datDir,'fibers');
        if(~exist(roiPath,'dir')), mkdir(roiPath); end
        if(~exist(fgPath,'dir')), mkdir(fgPath); end

        [dt,t1] = dtiLoadDt6(datFiles(ii).dt6, applyBrainMask);
        figFile = fullfile(checkCCDir, [datFiles(ii).subDir '.png']);
        %figFile = [];
        if(~isempty(datFiles(ii).ccRoiFname) && exist(datFiles(ii).ccRoiFname,'file'))
            ccRoi = dtiReadRoi(datFiles(ii).ccRoiFname);
        else
            ccRoi = dtiNewRoi('CC','c',dtiFindCallosum(dt.dt6, dt.b0, dt.xformToAcpc, ccThresh, figFile, 0));
            datFiles(ii).ccRoiFname = fullfile(roiPath, ccRoi.name);
            dtiWriteRoi(ccRoi, datFiles(ii).ccRoiFname);
        end

        fa = dtiComputeFA(dt.dt6);

        mask = fa>=faThresh;
        [x,y,z] = ind2sub(size(mask), find(mask));
        roiAll = dtiNewRoi('all',[],mrAnatXformCoords(dt.xformToAcpc, [x,y,z]));

        % LEFT WM ROI
        roiLeft = dtiRoiClip(roiAll, [0 80]);
        roiLeft = dtiRoiClean(roiLeft, 3, {'fillHoles', 'removeSat'});
        roiLeft.name = 'allLeft';

        % RIGHT WM ROI
        roiRight = dtiRoiClip(roiAll, [-80 0]);
        roiRight = dtiRoiClean(roiRight, 3, {'fillHoles', 'removeSat'});
        roiRight.name = 'allRight';

        % Track all fiber in each hemisphere, then intersect each with the CC
        % ROI. These fiber groups will be saved to disk.
        fg = dtiFiberTrack(dt.dt6, roiLeft.coords, dt.mmPerVoxel, dt.xformToAcpc, [roiLeft.name 'FG'], opts);
        fg = dtiIntersectFibersWithRoi(0, {'and'}, [], ccRoi, fg);
        fg.name = strrep(fg.name,'_man','');
        fg = dtiCleanFibers(fg,[],maxFiberLen);
        dtiWriteFiberGroup(fg, fullfile(fgPath, fg.name), 1, 'acpc');
        clear fg;

        fg = dtiFiberTrack(dt.dt6, roiRight.coords, dt.mmPerVoxel, dt.xformToAcpc, [roiRight.name 'FG'], opts);
        fg = dtiIntersectFibersWithRoi(0, {'and'}, [], ccRoi, fg);
        fg.name = strrep(fg.name,'_man','');
        fg = dtiCleanFibers(fg,[],maxFiberLen);
        dtiWriteFiberGroup(fg, fullfile(fgPath, fg.name), 1, 'acpc');
        clear fg;
        fprintf('  (elapsed time = %0.1f minutes)...\n',toc/60);
    end
end

logFile = fopen(logFileName,'wt');

segNames = {'Occ','Temp','PostPar','SupPar','SupFront','AntFront','Orb'};%,'LatFront'};
% NaN means no clip plane, 0 means clip at the SI/LR plane passing
% through the CC midpoint, -1 clips at the SI/LR plane passing
% through the posterior edge of the CC, and +1 clips at the
% anterior edge of the CC.
% We clip fibers from the anterior frontal FGs that go too
% far posterior. (eg. some tapetum fibers that make a wrong
% turn pass through the anterior frontal ROI.), and similarly
% for posterior FGs that extend too far anterior.
clipPlane = [0 NaN 0 0.166 NaN 0 0];
colors = [20 200 20; 200 20 200; 200 200 20; 20 90 200; 200 20 20; 235 165 55; 55 165 235; 20 20 100];

clear segs;
for(ii=1:length(segNames))
    segs(ii).name = segNames{ii};
    segs(ii).roi = ['Mori_%s' segNames{ii}];
    segs(ii).color = colors(ii,:);
    segs(ii).clipPlane = clipPlane(ii);
end
segs(end+1).name = 'Scraps';
segs(end).color = [100 100 100];

%% Find the fibers by intersecting with pre-defined ROIs
%
clear fg;
nSubs = 0;
nSegs = length(segs)-1; % the last seg is just scraps
allSegs = [1:nSegs];
%doSubs = find([datFiles.year]==3);
doSubs = [1:n];
for(ii=doSubs)
    tic
    clear newFg;
    fname = datFiles(ii).dt6;
    disp(['Processing ' fname '...']);
    fprintf(logFile, ['Processing ' fname ': ']);
    fiberPath = datFiles(ii).fiberDir;

    if(~exist(datFiles(ii).ccRoiFname,'file')&&~exist([datFiles(ii).ccRoiFname '.mat'],'file'))
        disp('    no CC roi- skipping...');
        fprintf(logFile, 'no CC roi- skipping.\n');
        continue;
    end
    cc = dtiReadRoi(datFiles(ii).ccRoiFname);

    if(length(dir(fullfile(datFiles(ii).moriRoiDir,'Mori_*')))<10)
        disp('   no Mori ROIs found- skipping...');
        fprintf(logFile, 'no Mori ROIs- skipping.\n');
    else
        try
            % Load all the ROIs
            for(jj=1:nSegs)
                roiL(jj) = dtiReadRoi(fullfile(datFiles(ii).moriRoiDir, sprintf(segs(jj).roi,'L')));
                roiR(jj) = dtiReadRoi(fullfile(datFiles(ii).moriRoiDir, sprintf(segs(jj).roi,'R')));
            end
        catch
            disp('   some Mori ROIs missing- skipping...');
            fprintf(logFile, 'some missing Mori ROIs- skipping.\n');
            continue;
        end

        lfgName = fullfile(fiberPath,'allLeftFG+CC.mat');
        rfgName = fullfile(fiberPath,'allRightFG+CC.mat');
        fgL = dtiReadFibers(lfgName);
        fgR = dtiReadFibers(rfgName);
        fgL = dtiCleanFibers(fgL);
        fgR = dtiCleanFibers(fgR);
        for(jj=1:nSegs)
            tmpFgL = dtiIntersectFibersWithRoi(0, {'and'}, 1, roiL(jj), fgL);
            tmpFgR = dtiIntersectFibersWithRoi(0, {'and'}, 1, roiR(jj), fgR);
            % Remove fibers that intersect with other ROIs with exception for temp
            % fibers do not exclude those that follow ILF into orb and anterior
            % frontal ROIs
            if(jj==2)
                tmpFgL = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:jj-1,jj+1:5]), tmpFgL);
                tmpFgR = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:jj-1,jj+1:5]), tmpFgR);
            else
                tmpFgL = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:jj-1,jj+1:nSegs]), tmpFgL);
                tmpFgR = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:jj-1,jj+1:nSegs]), tmpFgR);
            end

            if(~isnan(segs(jj).clipPlane))
                ccLength = max(cc.coords(:,2))-min(cc.coords(:,2));
                ccMid = min(cc.coords(:,2))+ccLength/2;
                apClip = segs(jj).clipPlane*0.5*ccLength+ccMid;

                % Remove any fibers that pass though the apClip plane
                nfp = cellfun('size',tmpFgL.fibers,2);
                allFC = horzcat(tmpFgL.fibers{:});
                if(~isempty(allFC))
                    apStat = allFC(2,:)>apClip;
                    keep = true(size(tmpFgL.fibers));
                    for(kk=1:length(keep))
                        if(kk==1), startInd = 1; else startInd = sum(nfp(1:kk-1))+1; end
                        keep(kk) = all(apStat(startInd:startInd+nfp(kk)-1)) || all(~apStat(startInd:startInd+nfp(kk)-1)) ;
                    end
                    tmpFgL.fibers = tmpFgL.fibers(keep);
                end

                nfp = cellfun('size',tmpFgR.fibers,2);
                allFC = horzcat(tmpFgR.fibers{:});
                if(~isempty(allFC))
                    apStat = allFC(2,:)>apClip;
                    keep = true(size(tmpFgR.fibers));
                    for(kk=1:length(keep))
                        if(kk==1), startInd = 1; else startInd = sum(nfp(1:kk-1))+1; end
                        keep(kk) = all(apStat(startInd:startInd+nfp(kk)-1)) || all(~apStat(startInd:startInd+nfp(kk)-1)) ;
                    end
                    tmpFgR.fibers = tmpFgR.fibers(keep);
                end
                %tmpFgL = dtiCleanFibers(tmpFgL, [NaN apClip NaN]);
                %tmpFgR = dtiCleanFibers(tmpFgR, [NaN apClip NaN]);
            end
            newFg(jj,1) = tmpFgL;
            newFg(jj,1).name = [segs(jj).name 'L'];
            newFg(jj,1).colorRgb = segs(jj).color;
            newFg(jj,2) = tmpFgR;
            newFg(jj,2).name = [segs(jj).name 'R'];
            newFg(jj,2).colorRgb = segs(jj).color;
        end
        % The last ROI is for the 'scraps'- those not caught by any ROI
        newFg(nSegs+1,1) = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:nSegs]), fgL);
        newFg(nSegs+1,2) = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiR([1:nSegs]), fgR);
        newFg(nSegs+1,1).name = 'ScrapsL';
        newFg(nSegs+1,2).name = 'ScrapsR';

        nSubs = nSubs+1;
        % ****************************
        % Find mid-sag fiber crossings
        %
        ccCoords{nSubs} = cc.coords(cc.coords(:,1)==min(abs(cc.coords(:,1))),:)';
        for(kk=1:size(newFg,1))
            for(ll=1:size(newFg,2))
                nFibers = length(newFg(kk,ll).fibers);
                fiberCC(nSubs,kk,ll).fiberCoord = single(zeros(3,nFibers,nSampsPerFiber)*NaN);
                if(nFibers==0), continue; end
                % Speed up the following loop by calling nearpoints just once
                % for all fiber coords, then loop over each fiber to sort out
                % the fiberCoords.
                [nearCoords, distSqAll] = nearpoints(horzcat(newFg(kk,ll).fibers{:}), ccCoords{nSubs});
                nfp = cellfun('size',newFg(kk,ll).fibers,2);
                for(jj=1:nFibers)
                    % for each fiber point, find the nearest CC ROI point
                    %[nearCoords, distSq] = nearpoints(newFg(kk,ll).fibers{jj}, ccCoords{nSubs});
                    % for all fiber points, select the one that is closest to a
                    % midSag point. We'll store this one as the point where this
                    % fiber passes through the mid sag plane.
                    if(jj==1), startInd = 1; else startInd = sum(nfp(1:jj-1))+1; end
                    distSq = distSqAll(startInd:startInd+nfp(jj)-1);
                    nearest = find(distSq==min(distSq));
                    nearest = nearest(1);
                    fiberCC(nSubs,kk,ll).dist(jj) = single(sqrt(distSq(nearest)));
                    fiberCoords = [nearest-mmBeyond:nearest+mmBeyond];
                    fiberCoords(fiberCoords<1) = NaN;
                    fiberCoords(fiberCoords>size(newFg(kk,ll).fibers{jj},2)) = NaN;
                    fiberCC(nSubs,kk,ll).fiberCoord(:,jj,~isnan(fiberCoords)) = ...
                        single(newFg(kk,ll).fibers{jj}(:,fiberCoords(~isnan(fiberCoords))));
                end
                goodFibers = all(all(~isnan(fiberCC(nSubs,kk,ll).fiberCoord),3),1);
                fiberCC(nSubs,kk,ll).fiberCoord = fiberCC(nSubs,kk,ll).fiberCoord(:,goodFibers,:);
            end
        end
        ccCoords{nSubs} = single(ccCoords{nSubs}(2:3,:));
        datSum(nSubs).subCode = datFiles(ii).sc;
        datSum(nSubs).fileName = datFiles(ii).dt6;
        datSum(nSubs).datDir = datFiles(ii).datDir;
        datSum(nSubs).moriRoiDir = datFiles(ii).moriRoiDir;
        datSum(nSubs).year = datFiles(ii).year;
        fprintf(logFile, 'SUCCESS!\n');
    end
    toc
end
clear cc tmpFgL tmpFgR roiL roiR fgL fgR newFg;
fclose(logFile);


%% Extract the diffusion properties of the fiber coords from the tensor field
%
clear fa md pdd dt6 nfa nmd npdd ndt6;
for(ii=1:nSubs)
    disp(['Computing diffusion properties for ' num2str(ii) ': ' datSum(ii).subCode '...']);
    dt = dtiLoadDt6(datSum(ii).fileName);
    for(jj=1:size(fiberCC,2))
        % There is a lot of redundancy in the tensor values, since many fibers
        % map onto the same voxel. To efficiently store the data, we combine left and
        % right coords and store only the unique tensor values plus a set of indices
        % into the unique list.
        numLeftFibers = size(fiberCC(ii,jj,1).fiberCoord,2);
        numRghtFibers = size(fiberCC(ii,jj,2).fiberCoord,2);
        coordsL = reshape(double(fiberCC(ii,jj,1).fiberCoord),3,numLeftFibers*nSampsPerFiber);
        coordsR = reshape(double(fiberCC(ii,jj,2).fiberCoord),3,numRghtFibers*nSampsPerFiber);
        coords = mrAnatXformCoords(inv(dt.xformToAcpc), horzcat(coordsL, coordsR));
        clear coordsL coordsR;
        %coords(any(isnan(coords),2),:) = [];
        % Nearest-neighbor interpolation
        if(~isempty(coords))
            [coords,junk,inds] = unique(round(coords), 'rows');
            dt6Inds{ii,jj,1} = reshape(uint16(inds(1:numLeftFibers*nSampsPerFiber)), numLeftFibers, nSampsPerFiber);
            dt6Inds{ii,jj,2} = reshape(uint16(inds(numLeftFibers*nSampsPerFiber+1:end)), numRghtFibers, nSampsPerFiber);
            [dxx,dyy,dzz,dxy,dxz,dyz] = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','nearest');
            %dt6_L{ii,jj} = single(reshape([dxx dyy dzz dxy dxz dyz], nFibers, nSampsPerFiber, 6));
            dt6Vals{ii,jj} = reshape([dxx dyy dzz dxy dxz dyz], size(coords,1), 6);
        else
            dt6Vals{ii,jj} = [];
        end
    end
end
clear dxx dyy dzz dxy dxz dyz coords junk inds dt;

%% Save results
%
save(fullfile(outDir,outFileName),'datSum','ccCoords','fiberCC','segs','dt6Inds','dt6Vals');
error('Stop here.');
% Matlab mat files (before 7.4) are limited to variables whose
% storage requirements are <=2^31.




%% Extras
% Create and save the 3-axis 'screen-save' images showing the fiber groups
% on select slices.
upSamp = 2;
acpcPos = [0 -50 10];
for(ii=1:nSubs)
    disp(['Processing ' num2str(ii) ': ' subCode{ii} '...']);

    % Generate the slice images
    dt = load(fileName{ii}, 'xformToAnat', 'anat');
    bg = dt.anat;
    bg.img = mrAnatHistogramClip(double(bg.img), 0.4, 0.98);
    bg.acpcToImgXform = inv(bg.xformToAcPc);

    fname = fullfile(outDir, 'overlayMaps', [sc{ii} '_LRocc']);
    dtiSaveImageSlicesOverlays(0, fg(ii,:), [], 0, fname, upSamp, acpcPos, bg);
end


