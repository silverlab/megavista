% This script can be used to analyze DTI data for the optic radiations.
%
% This script does the following:
% 1. Generates the paths using a variant of MetroTrac (do this on teal!)
% 2. Runs resampling of the paths (do this on teal!)
% 3. Cleans and saves the fiber groups
% 4. Summarizes the properties of the fiber groups

%% settings
doControl           = false;
doLV                = true;
% If the bin directory containing these files exists, skip this.  Otherwise
% run it.  If it exists, but is older than August 25th 2006, you need to
% run this because MetroTrac only appeared in our hands that date.
convertDt6          = true;
computePaths        = false;
resamplePaths       = false;
cleanPaths          = false;
clusterPaths        = false;
computeFiberDensity = false;
summarizePaths      = false;
compareNVLV         = false;

% set up pointers to subject dirs
if doControl % normally sighted
    subjectCode = { 'me050126' };
    %     subjectCode = { 'aab050307', 'ah051003', 'as050307', 'aw040809', ...
    %         'ct060309', 'gf050826', 'gm050308', 'jy060309', ...
    %         'ka040923', 'mbs040503', 'me050126', 'mz040828', ...
    %         'pp050208', 'rfd040630', 'sn040831', 'sp050303' };
    if ispc
        baseDir = 'R:\data\reading_longitude\dti_adults';
    else
        baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults';
    end
elseif doLV
    subjectCode = { 'kp051022' };
    if ispc
        baseDir = 'Q:\data\Plasticity\LCA\dti';
    else
        baseDir = '/biac2/wandell/data/Plasticity/LCA/dti';
    end    
else % patients with visual impairment
    subjectCode = { 'mm040325' };
    %     subjectCode = { 'mm040325', 'ms040629', 'wg031210' };
    if ispc
        baseDir = 'R:\data\DTI_Blind';
    else
        baseDir = '/biac2/wandell2/data/DTI_Blind';
    end
end

numSub = length(subjectCode);

leftRight = {'L','R'};

%%
% % % % % % % %
% convert dt6 %
% % % % % % % %

if convertDt6
    for subjectID = 1:numSub
        dataDir = fullfile(baseDir,subjectCode{subjectID});
        if doControl
            dt6File = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',subjectCode{subjectID}));
        else
            dt6File = fullfile(dataDir,sprintf('%s_dt6.mat',subjectCode{subjectID}));
        end
        dtiConvertDT6ToBinaries(dt6File);
    end
end

%%
% % % % % % % % %
% compute paths %
% % % % % % % % %

if computePaths
    for subjectID = 1:numSub
        dataDir = fullfile(baseDir,subjectCode{subjectID});
        if doControl
            dt6File = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',subjectCode{subjectID}));
        else
            dt6File = fullfile(dataDir,sprintf('%s_dt6.mat',subjectCode{subjectID}));
        end

        % left and right optic radiations
        for ii = 1:2
            roiNames = { sprintf('%sLgnRect',leftRight{ii}), ...
                sprintf('%sCalcarineRect',leftRight{ii}) };
            roi1File = fullfile(dataDir,'ROIs',roiNames{1});
            roi2File = fullfile(dataDir,'ROIs',roiNames{2});
            fgName   = [leftRight{ii},'OpticRadiation-',strrep(strrep(datestr(now),':','-'),' ','-'),'.dat'];
            fgFile   = fullfile(dataDir,'bin','metrotrac','sisr',fgName);

            samplerOptsFile = fullfile(dataDir,'bin','metrotrac','sisr',[leftRight{ii},'OR_met_params.txt']);
            mtrTwoRoiSampler(dt6File, roi1File, roi2File, samplerOptsFile, fgFile);
        end
    end
end

%%
% % % % % % % % % %
% resample paths  %
% % % % % % % % % %

numResample = 400000;

if resamplePaths
    for subjectID = 1:numSub
        dataDir = fullfile(baseDir,subjectCode{subjectID});
        sisrDir = fullfile(dataDir,'bin','metrotrac','sisr');

        % left and right optic radiations
        for ii = 1:2
            pathsFiles = dir(fullfile(sisrDir,[leftRight{ii},'OpticRadiation*.dat']));
            numFile    = length(pathsFiles);
            fgFiles    = cell(1,numFile);

            for jj = 1:numFile
                fgFiles{jj} = fullfile(sisrDir,pathsFiles(jj).name);
            end

            newFgFile = fullfile(sisrDir,['resamp',leftRight{ii},'OpticRadiation-',strrep(strrep(datestr(now),':','-'),' ','-'),'.dat']);
            samplerOptsFile = fullfile(sisrDir,[leftRight{ii},'OR_met_params.txt']);
            mtrResampleSISPathways(fgFiles,samplerOptsFile,numResample,newFgFile);
        end
    end
end

%%
% % % % % % % %
% clean paths %
% % % % % % % %

if cleanPaths
    for subjectID = 1:numSub
        dataDir   = fullfile(baseDir,subjectCode{subjectID});
        fiberPath = fullfile(dataDir,'fibers');
        sisrDir   = fullfile(dataDir,'bin','metrotrac','sisr');

        if doControl
            dt6File = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',subjectCode{subjectID}));
        else
            dt6File = fullfile(dataDir,sprintf('%s_dt6.mat',subjectCode{subjectID}));
        end
        try
            dt = load(dt6File,'xformToAcPc');
        catch
            dt.xformToAcpc = eye(4);
        end

        % left and right optic radiations
        for ii = 1:2
            pathsFile = dir(fullfile(sisrDir,['resamp',leftRight{ii},'OpticRadiation*.dat']));
            fgFile    = fullfile(sisrDir,pathsFile(1).name);
            fg        = mtrImportFibers(fgFile,dt.xformToAcPc);

            numPaths     = length(fg.fibers);
            pathLength   = cellfun('size',fg.fibers,2);
            pathLengthMu = mean(pathLength);
            pathLengthSD = std(pathLength);
            maxLength    = pathLengthMu + 2*pathLengthSD;

            fg      = dtiCleanFibers(fg,[],maxLength);
            fg.name = ['mtr_resamp',leftRight{ii},'OR_cleaned'];
            dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
        end
    end
end

%%
% % % % % % % % %
% cluster paths %
% % % % % % % % %

if clusterPaths
    for subjectID = 1:numSub
        dataDir   = fullfile(baseDir,subjectCode{subjectID});
        fiberPath = fullfile(dataDir,'fibers');

        if doControl
            dt6File = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',subjectCode{subjectID}));
        else
            dt6File = fullfile(dataDir,sprintf('%s_dt6.mat',subjectCode{subjectID}));
        end

        try
            dt = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');
        catch
            dt = load(dt6File,'dt6');
            dt.xformToAcpc = eye(4);
        end

        % left and right optic radiations
        for ii = 1:2
            pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned.mat']));
            fgFile    = fullfile(fiberPath,pathsFile(1).name);
            fg        = dtiReadFibers(fgFile);

            endPoints    = dtiPlotFiberEndPoints(fg);
            set(gcf,'Name',[subjectCode{subjectID},' - ',leftRight{ii},': Fiber End-Point Coordinates']);
            endPtCluster = logical(clusterdata(endPoints(:,3),'maxclust',2)-1);

            tmpFg        = fg;
            tmpFg.fibers = fg.fibers(endPtCluster);
            tmpFg.name   = ['mtr_resamp',leftRight{ii},'OR_cleaned_c1'];
            dtiWriteFiberGroup(tmpFg, fullfile(fiberPath, tmpFg.name), 1, 'acpc', []);

            tmpFg        = fg;
            tmpFg.fibers = fg.fibers(~endPtCluster);
            tmpFg.name   = ['mtr_resamp',leftRight{ii},'OR_cleaned_c2'];
            dtiWriteFiberGroup(tmpFg, fullfile(fiberPath, tmpFg.name), 1, 'acpc', []);
        end
    end
end

%%
% % % % % % % % % % % % %
% compute fiber density %
% % % % % % % % % % % % %

cmap       = autumn(256);
clipRange  = [1 10];
acpcSlices = -16:2:22;
plane      = 3; % axial
if computeFiberDensity
    for subjectID = 1:numSub
        dataDir   = fullfile(baseDir,subjectCode{subjectID});
        fiberPath = fullfile(dataDir,'fibers');

        if doControl
            dt6File = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',subjectCode{subjectID}));
        else
            dt6File = fullfile(dataDir,sprintf('%s_dt6.mat',subjectCode{subjectID}));
        end

        try
            dt = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');
        catch
            dt = load(dt6File,'dt6');
            dt.xformToAcpc = eye(4);
        end
        
        imSize  = size(dt.anat.img);
        imSize  = imSize(1:3);
        anatImg = mrAnatHistogramClip(double(dt.anat.img),0.4,0.98);
        
        mmPerVoxel     = [2 2 2];
        xformImgToAcpc = dt.anat.xformToAcPc/diag([dt.anat.mmPerVox 1]);

        % left and right optic radiations
        for ii = 1:2
            for jj = 1:2
                try
                    pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned_c',num2str(jj),'.mat']));
                    fgFile    = fullfile(fiberPath,pathsFile(1).name);
                    fg        = dtiReadFibers(fgFile);

                    disp('Calculating fiber density map ...');
                    fdImg = dtiComputeFiberDensityNoGUI(fg, xformImgToAcpc, imSize, 1);

                    img_filename = sprintf('mtr_%sOR_c%d_fd_image.nii.gz',leftRight{ii},jj);

                    msg = sprintf('Saving density image to %s ...',img_filename);
                    disp(msg);
                    img_filename = fullfile(fiberPath,img_filename);
                    dtiWriteNiftiWrapper(fdImg, dt.anat.xformToAcPc, img_filename);

                    overlayFName = sprintf('mtr_%sOR_c%d_fd_overlay.png',leftRight{ii},jj);
                    overlayFName = fullfile(fiberPath,overlayFName);
                    mrAnatOverlayMontage(fdImg, xformImgToAcpc, ...
                        anatImg, dt.anat.xformToAcPc, ...
                        cmap, clipRange, acpcSlices, overlayFName, plane, 1);
                    clear('fg','fdImg');
                catch

                end
            end
            pathsFile = dir(fullfile(fiberPath,['mtr_',leftRight{ii},'OR.mat']));
            fgFile    = fullfile(fiberPath,pathsFile(1).name);
            fg        = dtiReadFibers(fgFile);

            disp('Calculating fiber density map ...');
            fdImg = dtiComputeFiberDensityNoGUI(fg, xformImgToAcpc, imSize, 1);

            img_filename = sprintf('mtr_%sOR_fd_image.nii.gz',leftRight{ii});

            msg = sprintf('Saving density image to %s ...',img_filename);
            disp(msg);
            img_filename = fullfile(fiberPath,img_filename);
            dtiWriteNiftiWrapper(fdImg, dt.anat.xformToAcPc, img_filename);
            
            overlayFName = sprintf('mtr_%sOR_fd_overlay.png',leftRight{ii});
            overlayFName = fullfile(fiberPath,overlayFName);
            mrAnatOverlayMontage(fdImg, xformImgToAcpc, ...
                anatImg, dt.anat.xformToAcPc, ...
                cmap, clipRange, acpcSlices, overlayFName, plane, 1);
            clear('fg','fdImg');
        end
        pathsFile = dir(fullfile(fiberPath,'mtr_OR.mat'));
        fgFile    = fullfile(fiberPath,pathsFile(1).name);
        fg        = dtiReadFibers(fgFile);

        disp('Calculating fiber density map ...');
        fdImg = dtiComputeFiberDensityNoGUI(fg, xformImgToAcpc, imSize, 1);

        img_filename = 'mtr_OR_fd_image.nii.gz';

        msg = sprintf('Saving density image to %s ...',img_filename);
        disp(msg);
        img_filename = fullfile(fiberPath,img_filename);
        dtiWriteNiftiWrapper(fdImg, dt.anat.xformToAcPc, img_filename);
        
        overlayFName = 'mtr_OR_fd_overlay.png';
        overlayFName = fullfile(fiberPath,overlayFName);
        mrAnatOverlayMontage(fdImg, xformImgToAcpc, ...
            anatImg, dt.anat.xformToAcPc, ...
            cmap, clipRange, acpcSlices, overlayFName, plane, 1);
        clear('fg','fdImg');
    end
end

%%
% % % % % % % % % %
% summarize paths %
% % % % % % % % % %

if summarizePaths

    for subjectID = 1:numSub

        dataDir   = fullfile(baseDir,subjectCode{subjectID});
        fiberPath = fullfile(dataDir,'fibers');

        if doControl
            dt6File = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',subjectCode{subjectID}));
        else
            dt6File = fullfile(dataDir,sprintf('%s_dt6.mat',subjectCode{subjectID}));
        end

        try
            dt = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');
        catch
            dt = load(dt6File,'dt6');
            dt.xformToAcpc = eye(4);
        end

        % left and right optic radiations
        for ii = 1:2
            
            for jj = 1:2

                pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned_c',num2str(jj),'.mat']));
                fgFile    = fullfile(fiberPath,pathsFile(1).name);
                fg        = dtiReadFibers(fgFile);

                dtiPlotValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'shape');

            end
            
        end
        
    end
    
end

%             tmpFg = fg;
%             tmpFg.fibers = fg.fibers(endPtCluster);
%             fgData = dtiPlotValFromFibers(dt.dt6,tmpFg,inv(dt.xformToAcPc),'shape');
%             endPoints1    = dtiPlotFiberEndPoints(tmpFg);
% 
%             %             fgs(ii).fibers = fg.fibers;
% 
%             numPaths      = length(fg.fibers);
%             pathLength    = cellfun('size',fg.fibers,2);
%             minPathLength = min(pathLength);
%             % fgLogDt6      = zeros(minPathLength,6,numPaths);
%             % pathLengthMu  = mean(pathLength);
%             % pathLengthSD  = std(pathLength);
% 
%             fgDt6 = dtiGetValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'dt6','nearest');
% 
%             fgProp{subjectID,ii} = repmat(struct( ...
%                 'eigVec',     zeros(1,1), ...
%                 'eigVal',     zeros(1,1), ...
%                 'fa',         zeros(1,1), ...
%                 'md',         zeros(1,1), ...
%                 'linearity',  zeros(1,1), ...
%                 'planarity',  zeros(1,1), ...
%                 'sphericity', zeros(1,1)), numPaths, 1);
% 
%             for jj = 1:numPaths
%                 [fgProp{subjectID,ii}(jj).eigVec, ...
%                     fgProp{subjectID,ii}(jj).eigVal] = ...
%                     dtiEig(fgDt6{jj});
%                 [fgProp{subjectID,ii}(jj).fa, ...
%                     fgProp{subjectID,ii}(jj).md] = ...
%                     dtiComputeFA(fgProp{subjectID,ii}(jj).eigVal);
%                 [fgProp{subjectID,ii}(jj).linearity, ...
%                     fgProp{subjectID,ii}(jj).planarity, ...
%                     fgProp{subjectID,ii}(jj).sphericity] = ...
%                     dtiComputeWestinShapes(fgProp{subjectID,ii}(jj).eigVal);
% 
%                 vec = fgProp{subjectID,ii}(jj).eigVec(1:minPathLength,:,:);
%                 val = fgProp{subjectID,ii}(jj).eigVal(1:minPathLength,:);
% 
%                 val = log(val);
% 
%                 fgLogDt6{subjectID,ii}(1:minPathLength,:,jj) = dtiEigComp(vec,val);
%             end
% 
% 
%             figure; hold on;
%             for jj=1:numPaths
%                 plot(fgProp(jj).eigVal(:,1));
%             end
%             hold off;
% 
%             figure; hold on;
%             for jj=1:numPaths
%                 plot(fgProp(jj).eigVal(:,2));
%             end
%             hold off;
%             %
%             figure; hold on;
%             for jj=1:numPaths
%                 plot(fgProp(jj).fa);
%             end
%             hold off;
%             figure; hold on;
%             for jj=1:numPaths
%                 plot(fgProp{subjectID,ii}(jj).linearity);
%             end
%             hold off;
%             figure; hold on;
%             for jj=1:numPaths
%                 plot(fgProp{subjectID,ii}(jj).planarity);
%             end
%             hold off;
%             %
%             %             figure; hold on;
%             %             for jj=1:numPaths
%             %                 plot(fgProp(jj).md);
%             %             end
%             %             hold off;
% 
%         end
% 
% 
%         %         fdImg = dtiMakeFiberDensityImage(dt.dt6,fgs,dt.xformToAcPc,dt.mmPerVox);
%         %         normalizingFactor = 10;
%         %
%         %         % overlay p-value map on t1 images
%         %         cmap    = autumn(256);
%         %
%         %         % create rgb version of t1
%         %         anatRgb = repmat(mrAnatHistogramClip(double(dt.anat.img),0.4,0.98),[1,1,1,3]);
%         %
%         %         % reslice p-value map to t1 space
%         %         tmp = mrAnatResliceSpm(fdImg, inv(dt.xformToAcPc), [], dt.anat.mmPerVox, [1 1 1 0 0 0]);
%         %
%         %         % scale the range of p-value map to 0-1
%         %         tmp(tmp>normalizingFactor) = normalizingFactor;
%         %         tmp = (tmp-1)./(normalizingFactor-1);
%         %         overlayMask = tmp>=0;
%         %         tmp(~overlayMask) = 0;
%         %
%         %         % create rgb version of p-value map
%         %         overlayMask = repmat(overlayMask,[1 1 1 3]);
%         %         overlayRgb = reshape(cmap(round(tmp*255+1),:),[size(tmp) 3]);
%         %
%         %         % overlay p-value map onto t1
%         %         anatRgb(overlayMask) = overlayRgb(overlayMask);
%         %
%         %         % reorient so that the eyes point up
%         %         anatRgb = flipdim(permute(anatRgb,[2 1 3 4]),1);
%         %
%         %         % add slice labels
%         %         sl = [-20:5:20];
%         %         for ii=1:length(sl), slLabel{ii} = sprintf('Z = %d',sl(ii)); end
%         %         slImg = inv(dt.anat.xformToAcPc)*[zeros(length(sl),2) sl' ones(length(sl),1)]';
%         %         slImg = round(slImg(3,:));
%         %         anatOverlay = makeMontage3(anatRgb, slImg, dt.anat.mmPerVox(1), 0, slLabel);
%         %         % mrUtilPrintFigure(fullfile(outDir,'group_t1_faSPM'));
%         %
%         %         % create color bar
%         %         legendLabels = explode(',',sprintf('%0.1f,',[0:1:normalizingFactor]));
%         %         legendLabels{end} = ['>=' num2str(normalizingFactor)];
%         %         % mrUtilMakeColorbar(cmap, legendLabels, '-log10(p)', fullfile(outDir,'faSPM_legend'));
% 
%     end
% 
% end

%% compare MM to NVs

if compareNVLV
    nvCode = { 'aab050307', 'ah051003', 'as050307', 'aw040809', ...
        'ct060309', 'gf050826', 'gm050308', 'mbs040503', ...
        'me050126', 'rfd040630' };
    % nvCode = { 'aab050307', 'ah051003', 'as050307', 'aw040809', ...
    %     'ct060309', 'gf050826', 'gm050308', 'jy060309', ...
    %     'ka040923', 'mbs040503', 'me050126', 'mz040828', ...
    %     'pp050208', 'rfd040630', 'sn040831', 'sp050303' };
    if ispc
        nvDir = 'R:\data\reading_longitude\dti_adults';
    else
        nvDir = '/biac2/wandell2/data/reading_longitude/dti_adults';
    end

    lvCode = { 'mm040325' };
    % lvCode = { 'mm040325', 'ms040629', 'wg031210' };
    if ispc
        lvDir = 'R:\data\DTI_Blind';
    else
        lvDir = '/biac2/wandell2/data/DTI_Blind';
    end

    numNV = length(nvCode);

    leftRight = {'L','R'};

    figure;
    numStep = 40;
    fgData = cell(numNV,2);
    for subjectID = 1:numNV
        dataDir   = fullfile(nvDir,nvCode{subjectID});
        fiberPath = fullfile(dataDir,'fibers');
        dt6File   = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',nvCode{subjectID}));
        dt        = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');

        % left and right optic radiations
        for ii = 1:2
            pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned_c1.mat']));
            fgFile    = fullfile(fiberPath,pathsFile(1).name);
            fg        = dtiReadFibers(fgFile);

            fgData{subjectID,ii} = nanmean(dtiPlotValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'fa'));
            close(gcf);
            subplot(1,2,ii);
            hold on;
            plot(fgData{subjectID,ii}(1:numStep),'k-','linewidth',2);
        end
        clear dt fg;
    end

    subjectID = 1;
    dataDir   = fullfile(lvDir,lvCode{subjectID});
    fiberPath = fullfile(dataDir,'fibers');
    dt6File   = fullfile(dataDir,sprintf('%s_dt6.mat',lvCode{subjectID}));
    dt        = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');

    % left and right optic radiations
    for ii = 1:2
        pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned_c1.mat']));
        fgFile    = fullfile(fiberPath,pathsFile(1).name);
        fg        = dtiReadFibers(fgFile);

        fgData{numNV+subjectID,ii} = nanmean(dtiPlotValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'fa'));
        close(gcf);
        subplot(1,2,ii);
        hold on;
        plot(fgData{numNV+subjectID,ii}(1:numStep),'r-','linewidth',2);
        axis square;
    end
    clear dt fg;
    
    % shape
    figure;
    mrUtilResizeFigure(gcf,900,500);
    fgShape = cell(numNV,2,3);
    for subjectID = 1:numNV
        dataDir   = fullfile(nvDir,nvCode{subjectID});
        fiberPath = fullfile(dataDir,'fibers');
        dt6File   = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',nvCode{subjectID}));
        dt        = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');

        % left and right optic radiations
        for ii = 1:2
            pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned_c1.mat']));
            fgFile    = fullfile(fiberPath,pathsFile(1).name);
            fg        = dtiReadFibers(fgFile);
            
            cFgData = dtiPlotValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'shape');
            close(gcf);

            for jj = 1:3
                fgShape{subjectID,ii,jj} = nanmean(cFgData{jj});
                subplot(2,3,(ii-1)*3+jj);
                hold on;
                plot(fgShape{subjectID,ii,jj}(1:numStep),'k-','linewidth',2);
            end
        end
        clear dt fg;
    end

    subjectID = 1;
    dataDir   = fullfile(lvDir,lvCode{subjectID});
    fiberPath = fullfile(dataDir,'fibers');
    dt6File   = fullfile(dataDir,sprintf('%s_dt6.mat',lvCode{subjectID}));
    dt        = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');

    % left and right optic radiations
    for ii = 1:2
        pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned_c1.mat']));
        fgFile    = fullfile(fiberPath,pathsFile(1).name);
        fg        = dtiReadFibers(fgFile);

        cFgData = dtiPlotValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'shape');
        close(gcf);

        for jj = 1:3
            fgShape{numNV+subjectID,ii,jj} = nanmean(cFgData{jj});
            subplot(2,3,(ii-1)*3+jj);
            hold on;
            plot(fgShape{numNV+subjectID,ii,jj}(1:numStep),'r-','linewidth',2);
            axis square;
        end
    end
    clear dt fg;
    
    % eigVal
    diffusivityUnitStr = '(\mum^2/msec)';
    figure;
    mrUtilResizeFigure(gcf,900,500);
    fgDC = cell(numNV,2,3);
    for subjectID = 1:numNV
        dataDir   = fullfile(nvDir,nvCode{subjectID});
        fiberPath = fullfile(dataDir,'fibers');
        dt6File   = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',nvCode{subjectID}));
        dt        = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');

        % left and right optic radiations
        for ii = 1:2
            pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned_c1.mat']));
            fgFile    = fullfile(fiberPath,pathsFile(1).name);
            fg        = dtiReadFibers(fgFile);
            
            cFgData = dtiPlotValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'eigVal');
            close(gcf);

            for jj = 1:3
                fgDC{subjectID,ii,jj} = nanmean(cFgData{jj});
                subplot(2,3,(ii-1)*3+jj);
                hold on;
                plot(fgDC{subjectID,ii,jj}(1:numStep),'k-','linewidth',2);
            end
        end
        clear dt fg;
    end

    subjectID = 1;
    dataDir   = fullfile(lvDir,lvCode{subjectID});
    fiberPath = fullfile(dataDir,'fibers');
    dt6File   = fullfile(dataDir,sprintf('%s_dt6.mat',lvCode{subjectID}));
    dt        = load(dt6File,'anat','dt6','xformToAcPc','mmPerVox');

    % left and right optic radiations
    for ii = 1:2
        pathsFile = dir(fullfile(fiberPath,['mtr_resamp',leftRight{ii},'OR_cleaned_c1.mat']));
        fgFile    = fullfile(fiberPath,pathsFile(1).name);
        fg        = dtiReadFibers(fgFile);

        cFgData = dtiPlotValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'eigVal');
        close(gcf);

        for jj = 1:3
            fgDC{numNV+subjectID,ii,jj} = nanmean(cFgData{jj});
            subplot(2,3,(ii-1)*3+jj);
            hold on;
            plot(fgDC{numNV+subjectID,ii,jj}(1:numStep),'r-','linewidth',2);
            axis square;
        end
    end
    clear dt fg;
    
    figure;
    fontSize = 16;
    mrUtilResizeFigure(gcf,1000,1000);
    numSub = size(fgDC,1);
    for ii = 1:numSub
        if ii==numSub, lineCol = 'r';
        else           lineCol = 'k';
        end
        for jj = 1:2
            subplot(2,2,(jj-1)*2+1);
            hold on;
            plot(fgDC{ii,jj,1}(1:numStep)/1000,[lineCol '-'],'linewidth',1.5);
            subplot(2,2,(jj-1)*2+2);
            hold on;
            plot(mean([fgDC{ii,jj,2}(1:numStep);fgDC{ii,jj,3}(1:numStep)])/1000,[lineCol '-'],'linewidth',1.5);
        end
    end
    for ii = 1:4
        subplot(2,2,ii);
        axis square;
        grid on;
        if mod(ii,2)
            yLabelStr = sprintf('Longitudinal Diffusivity %s',diffusivityUnitStr);
            yLims = [1 1.8];
        else
            yLabelStr = sprintf('Radial Diffusivity %s',diffusivityUnitStr);
            yLims = [0.4 0.8];
        end
        xlabel('Distance from LGN along OR (mm)','FontSize',fontSize);
        ylabel(yLabelStr,'FontSize',fontSize);
        set(gca,'ylim',yLims,'FontSize',fontSize);
    end

    figure;
    fontSize = 16;
    mrUtilResizeFigure(gcf,1000,1000);
    numSub = size(fgShape,1);
    fgLinPln = cell(2,2);
    for ii = 1:numSub
        if ii==numSub, lineCol = [1 0 0];
        else           lineCol = [0.8 0.8 0.8];
        end
        for jj = 1:2
            for kk = 1:2
                subplot(2,2,(jj-1)*2+kk);
                hold on;
                if ii~=numSub
                    fgLinPln{jj,kk}(ii,1:numStep) = fgShape{ii,jj,kk}(1:numStep);
                else
                    errorbar(nanmean(fgLinPln{jj,kk}),nanstd(fgLinPln{jj,kk}),'-','color',[0.5 0.5 0.5],'linewidth',1.5);
                end
                plot(fgShape{ii,jj,kk}(1:numStep),'-','color',lineCol,'linewidth',1.5);
            end
        end
    end
    for ii = 1:4
        subplot(2,2,ii);
        axis square;
        grid on;
        if mod(ii,2)
            yLabelStr = 'Linearity';
            yLims = [0 0.5];
        else
            yLabelStr = 'Planarity';
            yLims = [0 0.5];
        end
        xlabel('Distance from LGN along OR (mm)','FontSize',fontSize);
        ylabel(yLabelStr,'FontSize',fontSize);
        set(gca,'ylim',yLims,'xlim',[0 numStep+1],'FontSize',fontSize);
    end
end
