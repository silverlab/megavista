% rd_mpDistributionCorAnalSingle.m
%
% version CorAnalSingle is for processing data from a single condition,
% primarily for the purpose of voxel selection.

%% Setup
hemi = 1;
scanDate = '20110901'; % CG: '20110128'; WC: '20110819'

plotFigs = 1;
saveAnalysis = 1;

condNames = {'All'};
numConditions = length(condNames);

switch hemi
    case 1 % left/blue
%         phaseBounds = [pi 2*pi];
        phaseBounds = [pi pi+pi/2];
    case 2 % right/yellow
%         phaseBounds = [0 pi];
        phaseBounds = [0 pi/2];
end

%% File I/O
fileBase = sprintf('lgnROI%dAnalysis_%s_mpDistributionCorAnal%s%s', hemi, scanDate, condNames{1}, datestr(now,'yyyymmdd'));
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
    
    % phase hist
    figure
    hist(corAnal.ph)
    xlabel('phase')
    title(sprintf('Hemi %d', hemi))

    % phase x co scatter
    figure
    scatter(corAnal.ph, ...
        corAnal.co, ...
        50,'k.')
    xlabel('phase')
    ylabel('co')
    title(sprintf('Hemi %d', ...
        hemi))
    
    % score histograms
    figure
    for cond = 1:length(condNames)
        subplot(length(condNames),1,cond)
        hist(corAnal.(fieldName)(:,cond))
        xlabel(fieldName)
        ylabel('Number of voxels')
        title(condNames{cond})
    end

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
        title(sprintf('Hemi %d, %s %s > %0.2f', ...
            hemi, condNames{cond}, fieldName, thresh.(fieldName)))
    end

    % boxplot
    figure
    boxplot(superScores.(fieldName),'labels',condNames)
    title(sprintf('Hemi %d, %s > %0.2f', hemi, fieldName, thresh.(fieldName)))

    % phase x co scatter for superthreshAll voxs
    figure
    scatter(corAnal.ph(superthreshAll), ...
        corAnal.co(superthreshAll), ...
        50,'k.')
    xlabel('phase')
    ylabel('co')
    title(sprintf('Hemi %d', ...
        hemi))

end

%% Save analysis
if saveAnalysis
    save(savePath,'hemi','scanDate','condNames','data','zScores','corAnal','corAnalFields','thresh','superthresh','superthreshVoxs','superScores','superthreshAll','superthreshAllVoxs')
end



