% rd_centerOfMass_multiVoxData.m

%% Setup
hemi = 2;

varThreshs = 0:.001:.01;
prop = .5;
voxelSelectionOption = 'varExp'; % all, varExp

plotFigs = 1;
% saveAnalysis = 0;
saveFigs = 1;

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);

plotFileBase = sprintf('lgnROI%dPlot_centerOfMass_prop%d_', hemi, round(prop*100));

%% Load data
load(loadPath)

%% Set coordinates and associated values
coords = figData.coordsInplane';
nVox = size(coords,1);

betas = squeeze(figData.glm.betas(1,1:2,:))';
topoData = betas*[.5 -.5]';
mapName = 'betaM-P';

%% Calculate centers for several varThreshs
for iVar = 1:length(varThreshs)
    
    %% Select voxels
    switch voxelSelectionOption
        case 'all'
            voxelSelector = logical(ones(1,length(topoData)));
        case 'varExp'
            %         varThresh = 0.005;
            varThresh = varThreshs(iVar);
            voxelSelector = figData.glm.varianceExplained > varThresh;
        otherwise
            error('voxelSelectionOption not found');
    end
    
    vals = topoData(voxelSelector);
    
    %% Analysis
    [centers voxsInGroup] = ...
        rd_findCentersOfMass(coords(voxelSelector,:), vals, prop, 'prop');
    
    centers1(iVar,:) = centers{1};
    centers2(iVar,:) = centers{2};
    
    nSuperthreshVox(iVar,1) = numel(vals);
    
end

%% Plot figs
if plotFigs
    dimLabels = {'X','Y','Z'};
    f = figure;
    for iDim = 1:3
        subplot(4,1,iDim)
        hold on
        plot(varThreshs, centers1(:,iDim),'r')
        plot(varThreshs, centers2(:,iDim),'b')
%         ylabel(sprintf('Dim %d', iDim))
        ylabel(dimLabels{iDim})
        
        if iDim==1
            title(sprintf('Hemi %d, %s', hemi, mapName))
            legend('more M','more P','location','Best')
        end
    end
    
    subplot(4,1,4)
    bar(varThreshs, nSuperthreshVox, 'g')
    xlim([varThreshs(1), varThreshs(end)])
    ylabel('num vox')
    xlabel('prop. variance explained threshold')
end

%% Save figs
plotSavePath = sprintf('%s%s', plotFileBase, datestr(now,'yyyymmdd'));

if saveFigs
    print(f,'-djpeg',sprintf('figures/%s', plotSavePath));
end


