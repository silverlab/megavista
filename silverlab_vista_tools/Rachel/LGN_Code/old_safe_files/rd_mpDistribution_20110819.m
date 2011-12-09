% rd_mpDistribution.m

%% Setup
hemi = 1;
scanDate = '20110819'; % CG: '20110128'; WC: '20110819'

plotFigs = 1;
saveAnalysis = 1;

condNames = {'MLow','MHigh','PLow','PHigh'};
numConditions = length(condNames);

%% File I/O
fileBase = sprintf('lgnROI%dAnalysis_%s_mpDistribution%s', hemi, scanDate, datestr(now,'yyyymmdd'));
savePath = sprintf('%s.mat', fileBase);

%% Load data from all conditions
for cond = 1:numConditions
    data(cond) = load(sprintf('lgnROI%dData_Avg%s_%s', ...
        hemi, condNames{cond}, scanDate));
end

%% Read z-scores
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

%% Contrast z-scores
contrasts.z(1).name = 'MHigh-MLow';
contrasts.z(1).data = zScores(:,2) - zScores(:,1);

contrasts.z(2).name = 'PHigh-PLow';
contrasts.z(2).data = zScores(:,4) - zScores(:,3);

contrasts.z(3).name = 'PLow-MLow';
contrasts.z(3).data = zScores(:,3) - zScores(:,1);

contrasts.z(4).name = 'PHigh-MHigh';
contrasts.z(4).data = zScores(:,4) - zScores(:,2);

contrasts.z(5).name = '(MHigh+PHigh)-(MLow+PLow)';
contrasts.z(5).data = (zScores(:,2)+zScores(:,4)) - (zScores(:,1)+zScores(:,3));

contrasts.z(6).name = '(PLow+PHigh)-(MLow+MHigh)';
contrasts.z(6).data = (zScores(:,3)+zScores(:,4)) - (zScores(:,1)+zScores(:,2));

numContrasts = length(contrasts.z);

contrastNames = cell(numContrasts,1);
[contrastNames{:}] = deal(contrasts.z.name);

%% Copy z-contrasts
for contrast = 1:numContrasts
    zContrasts(:,contrast) = contrasts.z(contrast).data;
end

%% Highest z-scores per cond
zThresh = 1.5;
for cond = 1:numConditions
    superthreshZs(:,cond) = ...
        zScores(:,strcmp(condNames,condNames(cond))) > zThresh;
end

superthreshVoxs = any(superthreshZs,2);
superZScores = zScores(superthreshVoxs,:);

%% Orthogonal contrasts
contrasts.zo(1).name = 'M-P';
contrasts.zo(1).coefs = [1 1 -1 -1];

contrasts.zo(2).name = 'High-Low';
contrasts.zo(2).coefs = [-1 1 -1 1];

contrasts.zo(3).name = 'Interaction';
contrasts.zo(3).coefs = [1 -1 -1 1];

contrasts.zo(4).name = 'Mean';
contrasts.zo(4).coefs = [1 1 1 1];

numZOContrasts = length(contrasts.zo);
zoContrastNames = cell(numZOContrasts,1);
[zoContrastNames{:}] = deal(contrasts.zo.name);

for contrast = 1:numZOContrasts
    contrasts.zo(contrast).data = zScores*contrasts.zo(contrast).coefs';
    zoContrasts(:,contrast) = contrasts.zo(contrast).data;
end

%% Most responsive voxels on average, across conditions
zMeanThresh = 2;
superthreshMeanVoxs = ...
    zoContrasts(:,strcmp(zoContrastNames,'Mean')) > zMeanThresh;

%% Plot figures
if plotFigs
    
    %% Z-SCORES
    % boxplot
    figure
    boxplot(zScores,'labels',condNames)
    title(sprintf('Hemi %d', hemi))

    % 4-score imagesc
    figure
    imagesc(zScores(:,1:4))
    xlabel('z-score')
    ylabel('voxel')
    title(sprintf('Hemi %d Z-scores\n1 = %s\n2 = %s\n3 = %s\n4 = %s',...
        hemi, ...
        condNames{1}, ...
        condNames{2}, ...
        condNames{3}, ...
        condNames{4}));
    colorbar
    
    % 4-score scatter
    condsToPlot = 1:4;
    condToColor = 4;
    condsToPlot(condsToPlot==condToColor) = [];
    
    figure
    scatter3(zScores(:,condsToPlot(1)), ...
        zScores(:,condsToPlot(2)), ...
        zScores(:,condsToPlot(3)), ...
        15, zScores(:,condToColor))
    xlabel(condNames{condsToPlot(1)})
    ylabel(condNames{condsToPlot(2)})
    zlabel(condNames{condsToPlot(3)})
    title(sprintf('Hemi %d\nColor = %s', ...
        hemi, ...
        condNames{condToColor}))
    
    %% Z-CONTRASTS
    % boxplot
    figure
    boxplot(zContrasts(:,1:4),'labels',contrastNames(1:4))
    title(sprintf('Hemi %d', hemi))
    
    % 4-contrast imagesc
    figure
    imagesc(zContrasts(:,1:4))
    xlabel('zContrast')
    ylabel('voxel')
    title(sprintf('Hemi %d Contrasts\n1 = %s\n2 = %s\n3 = %s\n4 = %s',...
        hemi, ...
        contrasts.z(1).name, ...
        contrasts.z(2).name, ...
        contrasts.z(3).name, ...
        contrasts.z(4).name));
    colorbar
    
    % 4-contrast scatter
    contrastsToPlot = 1:4;
    contrastToColor = 2;
    contrastsToPlot(contrastsToPlot==contrastToColor) = [];
    
    figure
    scatter3(zContrasts(:,contrastsToPlot(1)), ...
        zContrasts(:,contrastsToPlot(2)), ...
        zContrasts(:,contrastsToPlot(3)), ...
        15, zContrasts(:,contrastToColor))
    xlabel(contrasts.z(contrastsToPlot(1)).name)
    ylabel(contrasts.z(contrastsToPlot(2)).name)
    zlabel(contrasts.z(contrastsToPlot(3)).name)
    title(sprintf('Hemi %d\nColor = %s', ...
        hemi, ...
        contrasts.z(contrastToColor).name))
    
    % 2-contrast imagesc
    figure
    imagesc(zContrasts(:,5:6))
    xlabel('zContrast')
    ylabel('voxel')
    title(sprintf('Hemi %d\nContrasts\n1 = %s\n2 = %s',...
        hemi, ...
        contrasts.z(5).name, ...
        contrasts.z(6).name));
    colorbar
    
    % 2-contrast scatter
    figure
    hold on
    scatter(zContrasts(:,5), zContrasts(:,6))
    xlabel('Contrast (Highs-Lows)')
    ylabel('StimType (Ps-Ms)')
    title(sprintf('Hemi %d', hemi))
    annotation('ellipse',dsxy2figxy([-2 -2 4 4]))
    xlims = get(gca, 'xlim');
    ylims = get(gca,'ylim');
    plot(xlims,[0 0],'--k')
    plot([0 0],ylims,'--k');
    
    %% SUPERTHRESH
    % z-scores for voxels superthreshold in each cond
    for cond = 1:numConditions
        figure
        plot(zScores(superthreshZs(:,cond),:))
        legend(condNames)
        xlim([0 nnz(superthreshZs(:,cond))])
        xlabel('voxel')
        ylabel('z-score')
        title(sprintf('Hemi %d, %s z > %0.1f', ...
            hemi, condNames{cond}, zThresh))
    end

    % boxplot
    figure
    boxplot(superZScores,'labels',condNames)
    title(sprintf('Hemi %d, z > %0.1f', hemi, zThresh))
    
    % 4-score scatter for z-scores of superthresh voxs
    condsToPlot = 1:4;
    condToColor = 4;
    condsToPlot(condsToPlot==condToColor) = [];
    
    figure
    scatter3(zScores(superthreshVoxs,condsToPlot(1)), ...
        zScores(superthreshVoxs,condsToPlot(2)), ...
        zScores(superthreshVoxs,condsToPlot(3)), ...
        15, zScores(superthreshVoxs,condToColor))
    xlabel(condNames{condsToPlot(1)})
    ylabel(condNames{condsToPlot(2)})
    zlabel(condNames{condsToPlot(3)})
    title(sprintf('Hemi %d\nColor = %s', ...
        hemi, ...
        condNames{condToColor}))
    
    %% ORTHOGONAL CONTRASTS
    % 4-contrast scatter
    contrastsToPlot = 1:4;
    contrastToColor = 4;
    contrastsToPlot(contrastsToPlot==contrastToColor) = [];
    
    figure
    scatter3(zoContrasts(:,contrastsToPlot(1)), ...
        zoContrasts(:,contrastsToPlot(2)), ...
        zoContrasts(:,contrastsToPlot(3)), ...
        15, zoContrasts(:,contrastToColor))
    xlabel(contrasts.zo(contrastsToPlot(1)).name)
    ylabel(contrasts.zo(contrastsToPlot(2)).name)
    zlabel(contrasts.zo(contrastsToPlot(3)).name)
    title(sprintf('Hemi %d\nColor = %s', ...
        hemi, ...
        contrasts.zo(contrastToColor).name))
    
    % 4-score scatter for zo-contrasts of superthresh mean voxs
    figure
    scatter3(zoContrasts(superthreshMeanVoxs,contrastsToPlot(1)), ...
        zoContrasts(superthreshMeanVoxs,contrastsToPlot(2)), ...
        zoContrasts(superthreshMeanVoxs,contrastsToPlot(3)), ...
        15, zoContrasts(superthreshMeanVoxs,contrastToColor))
    xlabel(contrasts.zo(contrastsToPlot(1)).name)
    ylabel(contrasts.zo(contrastsToPlot(2)).name)
    zlabel(contrasts.zo(contrastsToPlot(3)).name)
    title(sprintf('Hemi %d\nColor = %s', ...
        hemi, ...
        contrasts.zo(contrastToColor).name))
    
end

%% Save analysis
if saveAnalysis
    save(savePath,'hemi','scanDate','condNames','data','zScores','contrasts','zContrasts','zoContrasts','zThresh','superthreshZs')
end



