% rd_centerOfMass_multiVoxData.m

%% Setup
hemi = 2;

varThreshs = 0:.001:.05;
prop = .8;
voxelSelectionOption = 'varExp'; % all, varExp
betaCoefs = [0 1];
mapName = 'betaP';

plotFigs = 1;
saveAnalysis = 1;
saveFigs = 1;

%% File I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);
analysisSavePath = sprintf('%s_centerOfMass_%s_prop%d_%s.mat', fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
plotSavePath = sprintf('%sPlot_centerOfMass_%s_prop%d_%s', fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));

%% Load data
load(loadPath)

%% Set coordinates and associated values
coords = figData.coordsInplane';
nVox = size(coords,1);

betas = squeeze(figData.glm.betas(1,1:2,:))';
topoData = betas*betaCoefs';

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

%% Save data
C.hemi = hemi;
C.betaCoefs = betaCoefs;
C.mapName = mapName;
C.varThreshs = varThreshs;
C.prop = prop;
C.voxelSelectionOption = voxelSelectionOption;
C.centers1 = centers1;
C.centers2 = centers2;
C.nSuperthreshVox = nSuperthreshVox;
C.note = 'centers1 is from the higher-valued voxel group, centers2 from the lower-valued group';

if saveAnalysis
    save(analysisSavePath,'C')
end

%% Plot figs
if plotFigs
    dimLabels = {'X','Y','Z'};
    f = figure;
    for iDim = 1:3
        subplot(4,1,iDim)
        hold on
        plot(varThreshs, centers1(:,iDim),'b') % r
        plot(varThreshs, centers2(:,iDim),'k') % b
%         ylabel(sprintf('Dim %d', iDim))
        ylabel(dimLabels{iDim})
        
        if iDim==1
            title(sprintf('Hemi %d, %s, prop %.1f', hemi, mapName, prop))
            legend('more P','less P','location','Best')
        end
    end
    
    subplot(4,1,4)
    bar(varThreshs, nSuperthreshVox, 'g')
    xlim([varThreshs(1), varThreshs(end)])
    ylabel('num vox')
    xlabel('prop. variance explained threshold')
end

%% Save figs
% plotSavePath = sprintf('%s%s', plotFileBase, datestr(now,'yyyymmdd'));

if saveFigs
    print(f,'-djpeg',sprintf('figures/%s', plotSavePath));
end


