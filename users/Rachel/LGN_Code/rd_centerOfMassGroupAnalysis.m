% rd_centerOfMassGroupAnalysis.m

%% setup
[subjectDirs3T subjectDirs7T] = rd_lgnSubjects;
            
scanner = '7T';
mapName = 'betaP';
prop = 0.8;
analysisExtension = sprintf('centerOfMass_%s_prop%d_*', mapName, round(prop*100));
hemis = [1 2];

plotFigs = 1;
saveFigs = 0;
saveAnalysis = 1;

MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
colors = {MCol, PCol};

switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
    case '7T'
        subjectDirs = subjectDirs7T;
end

subjects = 1:size(subjectDirs,1);
% subjects = [1 2 4 5];
nSubjects = numel(subjects);

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
        groupData.centers1(:,:,iSubject,iHemi) = data.C.centers1;
        groupData.centers2(:,:,iSubject,iHemi) = data.C.centers2;
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
                normSte.centers1(:,iDim,hemi),{'Color',colors{2}});
            p2 = shadedErrorBar(varThreshs, groupMean.centers2(:,iDim,hemi), ...
                normSte.centers2(:,iDim,hemi),{'Color',[0 0 0]});
            ylabel(dimLabels{iDim})
            
            if iDim==1
                title(sprintf('Hemi %d, %s, prop %.1f', hemi, mapName, prop))
%                 legend('more M','more P','location','Best')
                legend([p1.mainLine p2.mainLine],{'more P','less P'},...
                    'location','Best')
            end
        end
        
        subplot(4,1,4)
        bar(varThreshs, groupMean.nSuperthreshVox(:,hemi), 'g')
        xlim([varThreshs(1), varThreshs(end)])
        ylabel('num vox')
        xlabel('prop. variance explained threshold')
    end
end

% set(sp(1,3),'YLim',[10.5 12.5])

%% save figs
if saveFigs
    for iHemi = 1:numel(f0)
        plotSavePath = sprintf('%s/figures/groupCenterOfMass_%s_hemi%d_%s',...
            fileBaseDir, fileBaseSubjects, iHemi, fileBaseTail);
        print(f0(iHemi),'-djpeg',sprintf(plotSavePath));
    end
end

%% save analysis
if saveAnalysis
    save(sprintf('%s/groupCenterOfMass_%s_%s.mat',...
        fileBaseDir, fileBaseSubjects, fileBaseTail), ...
        'groupData','groupMean','groupStd','groupSte',...
        'normData','normMean','normStd','normSte',...
        'mapName','prop','scanner','subjectDirs','subjects','hemis');
end


