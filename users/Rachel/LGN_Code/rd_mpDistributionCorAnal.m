% rd_mpDistributionCorAnal.m

%% Setup
hemi = 2;
scanDate = '20111025'; % CG: '20110128'; WC: '20110819'; WC_NEW: '20111025'

plotFigs = 1;
saveAnalysis = 1;

condNames = {'MLow','MHigh','PLow','PHigh'};
numConditions = length(condNames);

switch hemi
    case 1 % left/blue
        phaseBounds = [pi 2*pi];
    case 2 % right/yellow
        phaseBounds = [0 pi];
end

%% File I/O
fileBase = sprintf('lgnROI%dAnalysis_%s_mpDistributionCorAnal%s', hemi, scanDate, datestr(now,'yyyymmdd'));
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
    contrasts.(fieldName)(1).name = 'MHigh-MLow';
    contrasts.(fieldName)(1).coefs = [-1 1 0 0];

    contrasts.(fieldName)(2).name = 'PHigh-PLow';
    contrasts.(fieldName)(2).coefs = [0 0 -1 1];

    contrasts.(fieldName)(3).name = 'PLow-MLow';
    contrasts.(fieldName)(3).coefs = [-1 0 1 0];

    contrasts.(fieldName)(4).name = 'PHigh-MHigh';
    contrasts.(fieldName)(4).coefs = [0 -1 0 1];

    contrasts.(fieldName)(5).name = 'M-P';
    contrasts.(fieldName)(5).coefs = [1 1 -1 -1];

    contrasts.(fieldName)(6).name = 'High-Low';
    contrasts.(fieldName)(6).coefs = [-1 1 -1 1];

    contrasts.(fieldName)(7).name = 'Interaction';
    contrasts.(fieldName)(7).coefs = [1 -1 -1 1];

    contrasts.(fieldName)(8).name = 'Mean';
    contrasts.(fieldName)(8).coefs = [1 1 1 1];
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
thresh.amp = 1;
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
    
    % score histograms
    figure
    for cond = 1:length(condNames)
        subplot(length(condNames),1,cond)
        hist(corAnal.(fieldName)(:,cond))
        title(condNames{cond})
    end

    %% CONDITION CONTRASTS
    % boxplot
    figure
    boxplot(contrastData.(fieldName)(:,1:4),'labels',contrastNames(1:4))
    title(sprintf('Hemi %d', hemi))

    % 4-contrast imagesc
    figure
    imagesc(contrastData.(fieldName)(:,1:4))
    xlabel('zContrast')
    ylabel('voxel')
    title(sprintf('Hemi %d Contrasts\n1 = %s\n2 = %s\n3 = %s\n4 = %s',...
        hemi, ...
        contrasts.(fieldName)(1).name, ...
        contrasts.(fieldName)(2).name, ...
        contrasts.(fieldName)(3).name, ...
        contrasts.(fieldName)(4).name));
    colorbar

    % 4-contrast scatter
    contrastsToPlot = 1:4;
    contrastToColor = 2;
    contrastsToPlot(contrastsToPlot==contrastToColor) = [];

    figure
    scatter3(contrastData.(fieldName)(:,contrastsToPlot(1)), ...
        contrastData.(fieldName)(:,contrastsToPlot(2)), ...
        contrastData.(fieldName)(:,contrastsToPlot(3)), ...
        15, contrastData.(fieldName)(:,contrastToColor))
    xlabel(contrasts.(fieldName)(contrastsToPlot(1)).name)
    ylabel(contrasts.(fieldName)(contrastsToPlot(2)).name)
    zlabel(contrasts.(fieldName)(contrastsToPlot(3)).name)
    title(sprintf('Hemi %d %s\nColor = %s', ...
        hemi, ...
        fieldName, ...
        contrasts.(fieldName)(contrastToColor).name))

    % 2-contrast imagesc
    figure
    imagesc(contrastData.(fieldName)(:,5:6))
    xlabel('zContrast')
    ylabel('voxel')
    title(sprintf('Hemi %d\nContrasts\n1 = %s\n2 = %s',...
        hemi, ...
        contrasts.(fieldName)(5).name, ...
        contrasts.(fieldName)(6).name));
    colorbar

    % 2-contrast scatter
    figure
    hold on
    scatter(contrastData.(fieldName)(:,5), contrastData.(fieldName)(:,6))
    xlabel(contrasts.(fieldName)(5).name)
    ylabel(contrasts.(fieldName)(6).name)
    title(sprintf('Hemi %d %s', hemi, fieldName))
%     annotation('ellipse',dsxy2figxy([-2 -2 4 4]))
    axis equal
    xlims = get(gca, 'xlim');
    ylims = get(gca,'ylim');
    plot(xlims,[0 0],'--k')
    plot([0 0],ylims,'--k');

    %% SUPERTHRESH
    % scores for voxels superthreshold in each cond
    for cond = 1:numConditions
        figure
        superthreshInCond = corAnal.(fieldName)(superthresh.(fieldName)(:,cond),:);
        plot(sortrows(superthreshInCond,cond))
        legend(condNames)
        xlim([0 nnz(superthresh.(fieldName)(:,cond))])
        xlabel('voxel')
        ylabel(fieldName)
        title(sprintf('Hemi %d, %s %s > %0.1f', ...
            hemi, condNames{cond}, fieldName, thresh.(fieldName)))
    end

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
        15, superScores.(fieldName)(:,condToColor))
    xlabel(condNames{condsToPlot(1)})
    ylabel(condNames{condsToPlot(2)})
    zlabel(condNames{condsToPlot(3)})
    title(sprintf('Hemi %d, %s > %.2f\nColor = %s', ...
        hemi, fieldName, thresh.(fieldName), ...
        condNames{condToColor}))

    %% ORTHOGONAL CONTRASTS
    % 4-contrast scatter
    contrastsToPlot = 5:7;
    contrastToColor = 8;
    contrastsToPlot(contrastsToPlot==contrastToColor) = [];

    figure
    scatter3(contrastData.(fieldName)(:,contrastsToPlot(1)), ...
        contrastData.(fieldName)(:,contrastsToPlot(2)), ...
        contrastData.(fieldName)(:,contrastsToPlot(3)), ...
        15, contrastData.(fieldName)(:,contrastToColor))
    xlabel(contrasts.(fieldName)(contrastsToPlot(1)).name)
    ylabel(contrasts.(fieldName)(contrastsToPlot(2)).name)
    zlabel(contrasts.(fieldName)(contrastsToPlot(3)).name)
    title(sprintf('Hemi %d, %s\nColor = %s', ...
        hemi, fieldName, ...
        contrasts.(fieldName)(contrastToColor).name))

    % 4-score scatter for contrasts from voxels that meet all threshhold
    % criteria in any condition
    figure
    scatter3(contrastData.(fieldName)(superthreshAllVoxs,contrastsToPlot(1)), ...
        contrastData.(fieldName)(superthreshAllVoxs,contrastsToPlot(2)), ...
        contrastData.(fieldName)(superthreshAllVoxs,contrastsToPlot(3)), ...
        50, contrastData.(fieldName)(superthreshAllVoxs,contrastToColor),'.')
    xlabel(contrasts.(fieldName)(contrastsToPlot(1)).name)
    ylabel(contrasts.(fieldName)(contrastsToPlot(2)).name)
    zlabel(contrasts.(fieldName)(contrastsToPlot(3)).name)
    title(sprintf('Hemi %d, %s superthreshAll\nColor = %s', ...
        hemi, fieldName, ...
        contrasts.(fieldName)(contrastToColor).name))
    axis equal

end

%% Save analysis
if saveAnalysis
    save(savePath,'hemi','scanDate','condNames','data','corAnal','corAnalFields','contrasts','contrastData','thresh','superthresh','superthreshVoxs','superScores','superthreshAll','superthreshAllVoxs')
end



