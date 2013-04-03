% rd_centerOfMassNormGroupAnalysis.m

%% setup
[subjectDirs3T subjectDirs7T] = rd_lgnSubjects;
            
scanner = '3T';
mapName = 'betaP';
hemis = [1 2];
coordsType = 'Talairach'; %'Epi','Volume','Talairach'
coordsNorm = 'normalized'; % 'raw','normalized'

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
    case 'Volume'
        coordsExtension = 'Vol';
    case 'Talairach'
        coordsExtension = 'Tal';
    otherwise
        error('coordsType not recognized')
end

switch coordsNorm
    case 'raw'
        centersName = 'centers';
    case 'normalized'
        centersName = 'centersNorm';
    otherwise
        error('coordsNorm not recognized')
end

switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
        cVarThresh = .004; % for selecting the centers0 coordinate
    case '7T'
        subjectDirs = subjectDirs7T;
        cVarThresh = .02;
end
% cVarThresh = 0;

analysisExtension = sprintf('centerOfMass%sNorm_%s_prop%d_*', coordsExtension, mapName, round(prop*100));

% subjects = 1:size(subjectDirs,1);
% subjects = [1 2 3 4 5 7 8];
subjects = [1 2 4 5];
% subjects = 1:4;
nSubjects = numel(subjects);

for iS = 1:nSubjects
    subjStrs{iS} = num2str(subjects(iS));
end

%% File I/O
fileBaseDir = '/Volumes/Plata1/LGN/Group_Analyses';
fileBaseSubjects = sprintf('%s_N%d', scanner, nSubjects);
fileBaseTail = sprintf('%s_prop%d_centersThresh%03d_%s',...
        mapName, round(prop*100), round(cVarThresh*1000),...
        datestr(now,'yyyymmdd'));
            
%% get data from each subject
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    for iHemi = 1:length(hemis)
        hemi = hemis(iHemi);
        
        filePath = rd_getAnalysisFilePath(subjectDirs, scanner, ...
            subject, hemi, analysisExtension);

        data = load(filePath);
        
        groupData.varThreshs(:,iSubject,iHemi) = data.C.varThreshs;
        groupData.nSuperthreshVox(:,iSubject,iHemi) = data.C.nSuperthreshVox;
        
        % use raw or normalized data
        centers1 = data.(centersName){1};
        centers2 = data.(centersName){2};
        
        % flip and switch coords if volume
        if strcmp('coordsType','Volume')
            centers1 = [centers1(:,3) centers1(:,2)*(-1) centers1(:,1)*(-1)];
            centers2 = [centers2(:,3) centers2(:,2)*(-1) centers2(:,1)*(-1)];
        end
        
        groupData.centers1(:,:,iSubject,iHemi) = centers1;
        groupData.centers2(:,:,iSubject,iHemi) = centers2;
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

%% centers from all voxels (thresh=0) for all subjects and hemispheres 
threshIdx = find(groupMean.varThreshs(:,1)==cVarThresh);
for iHemi = 1:numel(hemis)
    centersThresh0{1,iHemi} = squeeze(groupData.centers1(threshIdx,:,:,iHemi))'; % [subject x coord]
    centersThresh0{2,iHemi} = squeeze(groupData.centers2(threshIdx,:,:,iHemi))';
end

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
            p1 = shadedErrorBar(varThreshs, groupMean.centers1(:,iDim,hemi), ...
                groupSte.centers1(:,iDim,hemi),{'Color',colors{1}});
            p2 = shadedErrorBar(varThreshs, groupMean.centers2(:,iDim,hemi), ...
                groupSte.centers2(:,iDim,hemi),{'Color',colors{2}});
            ylabel(dimLabels{iDim})
            
            if iDim==1
                title(sprintf('Hemi %d, %s, prop %.1f, %s coords', ...
                    hemi, mapName, prop, coordsType))
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
            text(centersThresh0{iC,iHemi}(:,1),centersThresh0{iC,iHemi}(:,3),subjStrs)
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
        if strcmp(coordsNorm,'normalized')
            xlim([0.2 0.8])
            ylim([0.1 0.7])
            xlabel('L-R center (normalized)')
            ylabel('V-D center (normalized)')
        else
            xlabel('L-R center (coord)')
            ylabel('V-D center (coord)')
        end
        axis square

        title(sprintf('Hemi %d, %s, prop %.1f at varThresh = %.3f, %s coords', ...
            hemi, mapName, prop, cVarThresh, coordsType))
    end
end

% set(sp(1,3),'YLim',[10.5 12.5])

%% save figs
if saveFigs
    for iHemi = 1:numel(f0)
        plotSavePath = sprintf('%s/figures/groupCenterOfMass%sNorm_%s_hemi%d_%s',...
            fileBaseDir, coordsExtension, fileBaseSubjects, iHemi, fileBaseTail);
        print(f0(iHemi),'-djpeg',sprintf(plotSavePath));
    end
    for iHemi = 1:numel(f1)
        scatterSavePath = sprintf('%s/figures/groupCenterOfMass%sNormXZ_%s_hemi%d_%s',...
            fileBaseDir, coordsExtension, fileBaseSubjects, iHemi, fileBaseTail);
        print(f1(iHemi),'-djpeg',sprintf(scatterSavePath));
    end
end

%% save analysis
if saveAnalysis
    save(sprintf('%s/groupCenterOfMass%sNorm_%s_%s.mat',...
        fileBaseDir, coordsExtension, fileBaseSubjects, fileBaseTail), ...
        'groupData','groupMean','groupStd','groupSte',...
        'centersThresh0','XZ','cVarThresh',...
        'mapName','prop','scanner','subjectDirs','subjects','hemis');
end


