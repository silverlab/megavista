% rd_mpDistributionCorAnalOrtho.m

%% Setup
hemi = 2;
scanDate = '20111025'; % CG: '20110128'; WC: '20110819'; CG & WC_NEW: '20111025'

plotFigs = 1;
saveAnalysis = 1;
saveFigs = 1;

condNames = {'M','P','High','Low'};
numConditions = length(condNames);

switch hemi
    case 1 % left/blue
        phaseBounds = [pi 2*pi];
    case 2 % right/yellow
        phaseBounds = [0 pi];
end

%% File I/O
fileBase = sprintf('lgnROI%dAnalysis_%s_mpDistributionCorAnalOrtho%s', hemi, scanDate, datestr(now,'yyyymmdd'));
savePath = sprintf('%s.mat', fileBase);

%% Load data from all conditions
for cond = 1:numConditions
    data(cond) = load(sprintf('lgnROI%dData_Avg%s_%s', ...
        hemi, condNames{cond}, scanDate));
end

%% Read z-scores (for comparison to corAnal data)
for cond = 1:numConditions
    zScores(:,cond) = data(cond).data.zScore; % z-scores from fft data
end

%% Read corAnal data
corAnalFields = {'co','amp','ph'};
for cond = 1:numConditions
    for field = 1:length(corAnalFields)
        fieldName = corAnalFields{field};
        corAnal.(fieldName)(:,cond) = data(cond).voxelCorAnal.(fieldName);
    end
end

%% Contrast corAnal data
for field = 1:length(corAnalFields)
    fieldName = corAnalFields{field};
    
    contrasts.(fieldName)(1).name = 'M-P';
    contrasts.(fieldName)(1).coefs = [1 -1 0 0];

    contrasts.(fieldName)(2).name = 'High-Low';
    contrasts.(fieldName)(2).coefs = [0 0 1 -1];

    contrasts.(fieldName)(3).name = 'Mean';
    contrasts.(fieldName)(3).coefs = [1 1 1 1];
end

numContrasts = length(contrasts.(fieldName));

contrastNames = cell(numContrasts,1);
[contrastNames{:}] = deal(contrasts.(fieldName).name);

%% Calculate contrast data
for field = 1:length(corAnalFields)
    fieldName = corAnalFields{field};
    for contrast = 1:numContrasts
        contrasts.(fieldName)(contrast).data = ...
            corAnal.(fieldName)*contrasts.(fieldName)(contrast).coefs';
        % copy contrast data
        contrastData.(fieldName)(:,contrast) = contrasts.(fieldName)(contrast).data;
    end
end

%% Highest magnitudes of different measures per cond
thresh.co = 0.19;
thresh.amp = 0;
thresh.ph = phaseBounds;
for field = 1:length(corAnalFields)
    fieldName = corAnalFields{field};
    for cond = 1:numConditions
        if numel(thresh.(fieldName))==1
            superthresh.(fieldName)(:,cond) = ...
                corAnal.(fieldName)(:,strcmp(condNames,condNames(cond))) > thresh.(fieldName);
        elseif numel(thresh.(fieldName))==2
            superthresh.(fieldName)(:,cond) = ...
                corAnal.(fieldName)(:,strcmp(condNames,condNames(cond))) > thresh.(fieldName)(1) & ...
                corAnal.(fieldName)(:,strcmp(condNames,condNames(cond))) < thresh.(fieldName)(2);
        else
            fprintf('\nToo many or too few elements in thresh.(fieldName)!\n\n')
        end
        superthreshVoxs.(fieldName) = any(superthresh.(fieldName),2);
    end
    superScores.(fieldName) = corAnal.(fieldName)(superthreshVoxs.(fieldName),:);
end

superthreshAll = superthresh.co & superthresh.amp & superthresh.ph;
superthreshAllVoxs = any(superthreshAll,2);

%% Plot figures
if plotFigs
    
    fieldToPlot = 'co';
    fieldName = fieldToPlot;

    %% SCORES
    % boxplot
    figure
    boxplot(corAnal.(fieldName),'labels',condNames)
    title(sprintf('Hemi %d %s', hemi, fieldName))

    % 4-score imagesc
    figure
    imagesc(corAnal.(fieldName)(:,1:4))
    xlabel(fieldName)
    ylabel('voxel')
    title(sprintf('Hemi %d %s\n1 = %s\n2 = %s\n3 = %s\n4 = %s',...
        hemi, ...
        fieldName, ...
        condNames{1}, ...
        condNames{2}, ...
        condNames{3}, ...
        condNames{4}));
    colorbar

    % 4-score scatter
    condsToPlot = 1:4;
    condToColor = 3;
    condsToPlot(condsToPlot==condToColor) = [];

    figure
    scatter3(corAnal.(fieldName)(:,condsToPlot(1)), ...
        corAnal.(fieldName)(:,condsToPlot(2)), ...
        corAnal.(fieldName)(:,condsToPlot(3)), ...
        50, corAnal.(fieldName)(:,condToColor),'.')
    xlabel(condNames{condsToPlot(1)})
    ylabel(condNames{condsToPlot(2)})
    zlabel(condNames{condsToPlot(3)})
    title(sprintf('Hemi %d %s\nColor = %s', ...
        hemi, ...
        fieldName, ...
        condNames{condToColor}))
    axis equal
    
    % score histograms
    histXRange = [0 .7];
    histYRange = [0 70];
    figure
    for cond = 1:length(condNames)
        subplot(length(condNames),1,cond)
        hist(corAnal.(fieldName)(:,cond))
        if cond==length(condNames)
            xlabel(sprintf('Hemi %d %s', hemi, fieldName))
            ylabel('num voxels')
        end
        title(condNames{cond})
        if ~isempty(histXRange)
            xlim(histXRange)
            ylim(histYRange)
        end
    end
    
    if saveFigs
        print(gcf, '-dtiff', sprintf('figures/lgnROI%dHist_%s_oConds_%s', ...
            hemi, scanDate, fieldName))
    end
    
    % pairwise scatter plots
    figure
    plotmatrix(corAnal.(fieldName), corAnal.(fieldName));

    %% CONDITION CONTRASTS
    % boxplot
    figure
    boxplot(contrastData.(fieldName)(:,1:3),'labels',contrastNames(1:3))
    title(sprintf('Hemi %d', hemi))

    % 3-contrast scatter
    contrastsToPlot = 1:3;
    contrastToColor = 3;
    contrastsToPlot(contrastsToPlot==contrastToColor) = [];

    figure
    hold on
    scatter(contrastData.(fieldName)(:,contrastsToPlot(1)), ...
        contrastData.(fieldName)(:,contrastsToPlot(2)), ...
        100, contrastData.(fieldName)(:,contrastToColor),'.')
    xlabel(contrasts.(fieldName)(contrastsToPlot(1)).name)
    ylabel(contrasts.(fieldName)(contrastsToPlot(2)).name)
    title(sprintf('Hemi %d %s\nColor = %s', ...
        hemi, ...
        fieldName, ...
        contrasts.(fieldName)(contrastToColor).name))
    axis equal
    xlims = get(gca, 'xlim');
    ylims = get(gca,'ylim');
    plot(xlims,[0 0],'--k')
    plot([0 0],ylims,'--k');
    
    if saveFigs
        print(gcf, '-dtiff', sprintf('figures/lgnROI%dScatter_%s_oContrasts_%s', ...
            hemi, scanDate, fieldName))
    end

    %% SUPERTHRESH
    % scores for voxels superthreshold in each cond
    for cond = 1:numConditions
        figure
        superthreshInCond = corAnal.(fieldName)(superthresh.(fieldName)(:,cond),:);
        superthreshInCondMeans(cond,:) = mean(superthreshInCond,1);
        plot(sortrows(superthreshInCond,cond))
        legend(condNames)
        xlim([0 nnz(superthresh.(fieldName)(:,cond))])
        xlabel('voxel')
        ylabel(fieldName)
        title(sprintf('Hemi %d, %s %s > %0.1f', ...
            hemi, condNames{cond}, fieldName, thresh.(fieldName)))
    end
    
    % for each superthresh cond, average of all other conds
    figure
    bar(superthreshInCondMeans)
    legend(condNames)
    xlabel('superthresh cond')
    ylabel(sprintf('mean %s of voxs superthresh in cond', fieldName))
    set(gca,'XTickLabel',condNames)

    % boxplot
    figure
    boxplot(superScores.(fieldName),'labels',condNames)
    title(sprintf('Hemi %d, %s > %0.1f', hemi, fieldName, thresh.(fieldName)))

    % 4-score scatter for z-scores of superthresh voxs
    condsToPlot = 1:4;
    condToColor = 4;
    condsToPlot(condsToPlot==condToColor) = [];

    figure
    scatter3(superScores.(fieldName)(:,condsToPlot(1)), ...
        superScores.(fieldName)(:,condsToPlot(2)), ...
        superScores.(fieldName)(:,condsToPlot(3)), ...
        100, superScores.(fieldName)(:,condToColor),'.')
    xlabel(condNames{condsToPlot(1)})
    ylabel(condNames{condsToPlot(2)})
    zlabel(condNames{condsToPlot(3)})
    title(sprintf('Hemi %d, %s > %.2f\nColor = %s', ...
        hemi, fieldName, thresh.(fieldName), ...
        condNames{condToColor}))
    axis equal

    % 4-score scatter for contrasts from voxels that meet all threshhold
    % criteria in any condition
    contrastsToPlot = 1:3;
    contrastToColor = 3;
    condtrastsToPlot(condsToPlot==condToColor) = [];
    
    figure
    hold on
    scatter(contrastData.(fieldName)(superthreshAllVoxs,contrastsToPlot(1)), ...
        contrastData.(fieldName)(superthreshAllVoxs,contrastsToPlot(2)), ...
        100, contrastData.(fieldName)(superthreshAllVoxs,contrastToColor),'.')
    xlabel(contrasts.(fieldName)(contrastsToPlot(1)).name)
    ylabel(contrasts.(fieldName)(contrastsToPlot(2)).name)
    title(sprintf('Hemi %d, %s superthreshAll\nColor = %s', ...
        hemi, fieldName, ...
        contrasts.(fieldName)(contrastToColor).name))
    axis equal
    xlims = get(gca, 'xlim');
    ylims = get(gca,'ylim');
    plot(xlims,[0 0],'--k')
    plot([0 0],ylims,'--k');
    
    if saveFigs
        print(gcf, '-dtiff', sprintf('figures/lgnROI%dScatter_%s_oSuperContrasts_%s', ...
            hemi, scanDate, fieldName))
    end
    
    % pairwise scatter plots for superthresh voxs
    figure
    plotmatrix(corAnal.co(superthreshAllVoxs,:),corAnal.co(superthreshAllVoxs,:));

end

%% Save analysis
if saveAnalysis
    save(savePath,'hemi','scanDate','condNames','data','corAnal','corAnalFields','contrasts','contrastData','thresh','superthresh','superthreshVoxs','superScores','superthreshAll','superthreshAllVoxs')
end



