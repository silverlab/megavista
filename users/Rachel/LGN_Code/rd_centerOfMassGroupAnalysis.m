% rd_centerOfMassGroupAnalysis.m

%% setup
[subjectDirs3T subjectDirs7T] = rd_lgnSubjects;
            
scanner = '3T';
mapName = 'betaM-P';
hemis = [1 2];
coordsType = 'Talairach'; %'Epi','Volume','Talairach'
%%% note!! Volume coords are switched and flipped compared to Epi/Tal. Need
%%% to fix if you want to plot these meaningfully.

plotFigs = 1;
saveFigs = 0;
saveAnalysis = 0;

MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
nullCol = [0 0 0]; % black
switch mapName
    case 'betaM-P'
        prop = 0.2;
        colors = {MCol, PCol};
        labels = {'more M','more P'};
    case 'betaM'
        prop = 0.2;
        colors = {MCol, nullCol};
        labels = {'more M','less M'};
    case 'betaP'
        prop = 0.8;
        colors = {PCol, nullCol};
        labels = {'more P','less P'};
    otherwise
        error('mapName not recognized')
end

for iCol = 1:numel(colors)
    hsvCol = rgb2hsv(colors{iCol});
    lightColors{iCol} = hsv2rgb([hsvCol(1) .3 1]);
end
if all(colors{2}==[0 0 0])
    lightColors{2}=[.6 .6 .6];
end

switch coordsType
    case 'Epi'
        coordsExtension = '';
        centers1Name = 'centers1';
        centers2Name = 'centers2';
    case 'Volume'
        coordsExtension = 'Vol';
        centers1Name = 'centers1Vol';
        centers2Name = 'centers2Vol';
    case 'Talairach'
        coordsExtension = 'Tal';
        centers1Name = 'centers1Tal';
        centers2Name = 'centers2Tal';
    otherwise
        error('coordsType not recognized')
end

switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
        voxelSize = [1.75 1.75 1.5];
%         voxelSize = repmat([1.75 1.75 1.5],4,1);
        
    case '7T'
        subjectDirs = subjectDirs7T;
%         voxelSize = [1.5 1.5 1.5];
        voxelSize = [1.3 1.3 1.3];
end

analysisExtension = sprintf('centerOfMass%s_%s_prop%d_*', coordsExtension, mapName, round(prop*100));
% subjects = 1:size(subjectDirs,1);
subjects = [1 2 4 5];
nSubjects = numel(subjects);

% if voxelSize is a 2D array, assume it is subject x dim
if size(voxelSize,1)==1
    mmMat = repmat(voxelSize,nSubjects,1);
else
    mmMat = voxelSize;
end

%% File I/O
fileBaseDir = '/Volumes/Plata1/LGN/Group_Analyses';
fileBaseSubjects = sprintf('%s_N%d', scanner, nSubjects);
fileBaseTail = sprintf('%s_prop%d_%s',...
        mapName, round(prop*100), datestr(now,'yyyymmdd'));
            
%% get data from each subject
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    for iHemi = 1:length(hemis)
        hemi = hemis(iHemi);
        
        filePath = rd_getAnalysisFilePath(subjectDirs, scanner, ...
            subject, hemi, analysisExtension);

        data = load(filePath);
        
        groupData.varThreshs(:,iSubject,iHemi) = data.C.varThreshs;
        groupData.centers1(:,:,iSubject,iHemi) = data.C.(centers1Name);
        groupData.centers2(:,:,iSubject,iHemi) = data.C.(centers2Name);
        groupData.nSuperthreshVox(:,iSubject,iHemi) = data.C.nSuperthreshVox;
    end
end

%% mean across subjects
groupMean.varThreshs = squeeze(mean(groupData.varThreshs,2)); % [varThreshs x hemi]
groupMean.centers1 = squeeze(mean(groupData.centers1,3)); % [varThresh x dim x hemi]
groupMean.centers2 = squeeze(mean(groupData.centers2,3)); % [varThresh x dim x hemi]
groupMean.nSuperthreshVox = squeeze(mean(groupData.nSuperthreshVox,2)); % [varThreshs x hemi]

%% standard deviation/error across subjects
groupStd.varThreshs = squeeze(std(groupData.varThreshs,0,2)); % [varThreshs x hemi]
groupStd.centers1 = squeeze(std(groupData.centers1,0,3)); % [varThresh x dim x hemi]
groupStd.centers2 = squeeze(std(groupData.centers2,0,3)); % [varThresh x dim x hemi]
groupStd.nSuperthreshVox = squeeze(std(groupData.nSuperthreshVox,0,2)); % [varThreshs x hemi]

fn = fieldnames(groupStd);
for iFn = 1:numel(fn)
    groupSte.(fn{iFn}) = groupStd.(fn{iFn})./sqrt(nSubjects);
end

%% NORMALIZATION
%% normalize coordinates by mean coordinates for each subject
nThresh = numel(data.C.varThreshs);
meanCenters1 = repmat(mean(groupData.centers1,1),[nThresh,1,1,1]);
meanCenters2 = repmat(mean(groupData.centers2,1),[nThresh,1,1,1]);

meanCenters = (meanCenters1 + meanCenters2)./2;

% normData.centers1 = groupData.centers1 - meanCenters1;
% normData.centers2 = groupData.centers2 - meanCenters2;

normData.centers1 = groupData.centers1 - meanCenters;
normData.centers2 = groupData.centers2 - meanCenters;

%% mean of normalized data across subjects
normMean.centers1 = squeeze(mean(normData.centers1,3)); % [varThresh x dim x hemi]
normMean.centers2 = squeeze(mean(normData.centers2,3)); % [varThresh x dim x hemi]

%% standard deviation/error of normalized dataacross subjects
normStd.centers1 = squeeze(std(normData.centers1,0,3)); % [varThresh x dim x hemi]
normStd.centers2 = squeeze(std(normData.centers2,0,3)); % [varThresh x dim x hemi]

fn = fieldnames(normStd);
for iFn = 1:numel(fn)
    normSte.(fn{iFn}) = normStd.(fn{iFn})./sqrt(nSubjects);
end

%% centers from all voxels (thresh=0) for all subjects and hemispheres 
for iHemi = 1:numel(hemis)
    centersThresh0Raw{1,iHemi} = squeeze(groupData.centers1(1,:,:,iHemi))'; % [subject x coord]
    centersThresh0Raw{2,iHemi} = squeeze(groupData.centers2(1,:,:,iHemi))';
    
    meanCenters0{iHemi} = squeeze((groupData.centers1(1,:,:,iHemi) + groupData.centers2(1,:,:,iHemi))./2)';

    for iC = 1:size(centersThresh0Raw,1)
        centersThresh0N{iC,iHemi} = centersThresh0Raw{iC,iHemi} - meanCenters0{iHemi};
        centersThresh0Nmm{iC,iHemi} = centersThresh0N{iC,iHemi}.*mmMat;
    end
end

% use centers normalized by the mean coordinate of the two centers groups 
% at thresh=0
centersThresh0 = centersThresh0Nmm;

for iSubject = 1:nSubjects
    for iHemi = 1:numel(hemis)
        x1(iSubject,iHemi) = centersThresh0{1,iHemi}(iSubject,1);
        z1(iSubject,iHemi) = centersThresh0{1,iHemi}(iSubject,3);
        x2(iSubject,iHemi) = centersThresh0{2,iHemi}(iSubject,1);
        z2(iSubject,iHemi) = centersThresh0{2,iHemi}(iSubject,3);
    end
end

% mean across subjects
xMean = [mean(x1,1); mean(x2,1)]; % [centers group x hemi]
zMean = [mean(z1,1); mean(z2,1)];

% ste across subjects
xSte = [std(x1,0,1)./sqrt(nSubjects); std(x2,0,1)./sqrt(nSubjects)];
zSte = [std(z1,0,1)./sqrt(nSubjects); std(z2,0,1)./sqrt(nSubjects)];

% store x and z coords
XZ.x1 = x1;
XZ.z1 = z1;
XZ.x2 = x2;
XZ.z2 = z2;
XZ.xMean = xMean;
XZ.zMean = zMean;
XZ.xSte = xSte;
XZ.zSte = zSte;
XZ.xzMeanSteDims = {'1st dim = centers group','2nd dim = hemi'};

%% PLOTS
if plotFigs
    varThreshs = groupMean.varThreshs(:,hemi);
    dimLabels = {'X','Y','Z'};
    for iHemi = 1:numel(hemis)
        hemi = hemis(iHemi);
        f0(iHemi) = figure;
        for iDim = 1:3
            sp(iHemi,iDim) = subplot(4,1,iDim);
            hold on
%             plot(varThreshs, groupMean.centers1(:,iDim,hemi),'r')
%             plot(varThreshs, groupMean.centers2(:,iDim,hemi),'b')

            if size(voxelSize,1)>1
                % units in voxels
                metricStr = 'voxel units';
                p1 = shadedErrorBar(varThreshs, groupMean.centers1(:,iDim,hemi), ...
                    normSte.centers1(:,iDim,hemi),{'Color',colors{1}});
                p2 = shadedErrorBar(varThreshs, groupMean.centers2(:,iDim,hemi), ...
                    normSte.centers2(:,iDim,hemi),{'Color',colors{2}});
            else
                % units in mm
                metricStr = 'mm units';
                p1 = shadedErrorBar(varThreshs, normMean.centers1(:,iDim,hemi)*voxelSize(iDim), ...
                    normSte.centers1(:,iDim,hemi)*voxelSize(iDim),{'Color',colors{1}});
                p2 = shadedErrorBar(varThreshs, normMean.centers2(:,iDim,hemi)*voxelSize(iDim), ...
                    normSte.centers2(:,iDim,hemi)*voxelSize(iDim),{'Color',colors{2}});
                ylabel(dimLabels{iDim})
            end
            
            if iDim==1
                title(sprintf('Hemi %d, %s, prop %.1f, %s coords, %s', ...
                    hemi, mapName, prop, coordsType, metricStr))
%                 legend('more M','more P','location','Best')
                legend([p1.mainLine p2.mainLine],labels,...
                    'location','Best')
            end
        end
        
        subplot(4,1,4)
        bar(varThreshs, groupMean.nSuperthreshVox(:,hemi), 'g')
        xlim([varThreshs(1), varThreshs(end)])
        ylabel('num vox')
        xlabel('prop. variance explained threshold')
    end
    
    % XZ scatter plot
    for iHemi = 1:numel(hemis)
        hemi = hemis(iHemi);
        f1(iHemi) = figure;
        hold on
        
        % plot each subject with connecting lines
        plot([x1(:,iHemi) x2(:,iHemi)]',[z1(:,iHemi) z2(:,iHemi)]',...
            'Color', [.7 .7 .7], 'LineWidth', 2)
        for iC = 1:size(centersThresh0,1)
            p3(iHemi,iC) = scatter(centersThresh0{iC,iHemi}(:,1), ...
                centersThresh0{iC,iHemi}(:,3), 100);
            set(p3(iHemi,iC), 'MarkerEdgeColor', lightColors{iC}, ...
                'MarkerFaceColor', lightColors{iC}, ...
                'LineWidth', 1)
        end
        
        % plot mean/ste across subjects, with connecting line
        plot(xMean(:,iHemi)',zMean(:,iHemi)','k', 'LineWidth', 1.2)
        for iC = 1:size(centersThresh0,1)
            errorxy([xMean(iC,iHemi),zMean(iC,iHemi),...
                xSte(iC,iHemi),zSte(iC,iHemi)],...
                'ColX',1','ColY',2,'ColXe',3,'ColYe',4,...
                'Marker','.','MarkSize',25,'EdgeColor',colors{iC},...
                'WidthEB',1.2);
        end
        xlim([-1.5 1.5])
        ylim([-1.5 1.5])
        xlabel('L-R center (mm)')
        ylabel('V-D center (mm)')
        title(sprintf('Hemi %d, %s, prop %.1f, %s coords', ...
            hemi, mapName, prop, coordsType))
    end
end

% set(sp(1,3),'YLim',[10.5 12.5])

%% save figs
if saveFigs
%     for iHemi = 1:numel(f0)
%         plotSavePath = sprintf('%s/figures/groupCenterOfMass_%s_hemi%d_%s',...
%             fileBaseDir, fileBaseSubjects, iHemi, fileBaseTail);
%         print(f0(iHemi),'-djpeg',sprintf(plotSavePath));
%     end
    for iHemi = 1:numel(f1)
        scatterSavePath = sprintf('%s/figures/groupCenterOfMassXZ%s_%s_hemi%d_%s',...
            fileBaseDir, coordsExtension, fileBaseSubjects, iHemi, fileBaseTail);
        print(f1(iHemi),'-djpeg',sprintf(scatterSavePath));
    end
end

%% save analysis
if saveAnalysis
    save(sprintf('%s/groupCenterOfMass%s_%s_%s.mat',...
        fileBaseDir, coordsExtension, fileBaseSubjects, fileBaseTail), ...
        'groupData','groupMean','groupStd','groupSte',...
        'normData','normMean','normStd','normSte',...
        'centersThresh0','XZ','centersThresh0Raw','meanCenters',...
        'centersThresh0N','centersThresh0Nmm',...
        'mapName','prop','scanner','subjectDirs','subjects','hemis');
end


