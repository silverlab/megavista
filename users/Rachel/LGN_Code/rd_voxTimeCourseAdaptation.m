% rd_voxTimeCourseAdaptation.m
%
% see tc_init.m

%% setup
hemi = 1;
voxelSelectionOption = 'voxGroup'; % varExp, beta, voxGroup
varThresh = 0;
betaThresh = 0;
betaCoefs = [.5 -.5];
prop = .2;
group = 1;
groupNames = {'M','P'};

saveData = 0;
saveFigs = 0;

%% analysis description for file saving
switch voxelSelectionOption
    case 'voxGroup'
        analysisDescrip = sprintf('%s%s_prop%d', ...
            voxelSelectionOption, groupNames{group}, prop*100);
    case 'varExp'
        analysisDescrip = sprintf('%s_thresh%03d', ...
            voxelSelectionOption, varThresh);
    otherwise
        error('voxelSelectionOption not found')
end

%% file I/O
fileBase = sprintf('lgnROI%d', hemi);
analysisExtension = '_multiVoxFigData';
loadPath = sprintf('%s%s.mat', fileBase, analysisExtension);
analysisSavePath = sprintf('%s_timeCoursesAdaptation_%s_%s.mat', ...
    fileBase, analysisDescrip, datestr(now,'yyyymmdd'));
plotSavePath = sprintf('figures/%sPlot_timeCoursesAdaptation_%s', ...
    fileBase, analysisDescrip);

%% load data
load(loadPath)

%% get data info
voxs = 1:size(figData.tSeries,2);

% recode trials depending on both the current trial and the preceding trial
trials = rd_adaptationRecodeCond(figData.trials);

nConds = numel(trials.condNums);
condNames = trials.condNames;
params = figData.params;

% reset any params
params.normBsl = 0;

% calculate frame window (in TRs) used by er_chopTSeries2 (lines 165-171)
timeWindow = params.timeWindow;
TR = trials.TR;
t1 = min(timeWindow);  t2 = max(timeWindow);
f1 = fix(t1 / TR);  f2 = fix(t2 / TR);
frameWindow = f1:f2;

%% voxel selection
betas = squeeze(figData.glm.betas(1,1:2,:))';
vals = betas*betaCoefs';

switch voxelSelectionOption
    case 'varExp'
        voxelSelector = figData.glm.varianceExplained > varThresh;
        voxDescrip = sprintf('varExp > %.02f', varThresh);
    case 'beta'
        voxelSelector = betas(:,group) > betaThresh;
        voxDescrip = sprintf('beta%s > %.02f', groupNames{group}, betaThresh);
    case 'voxGroup'
        [centers voxsInGroup] = ...
            rd_findCentersOfMass(figData.coordsInplane', vals, prop, 'prop');
        voxelSelector = voxsInGroup(:,group);
        voxDescrip = sprintf('group %s', groupNames{group});
    otherwise
        error('voxelSelectionOption not found')
end

%% choose voxels
voxs = voxs(voxelSelector);
nVox = numel(voxs);

%% get vox mean tcs for all voxels
voxMeanTcs = [];
for iVox = 1:nVox 
    voxIdx = voxs(iVox);
    voxtc = er_chopTSeries2(figData.tSeries(:,voxIdx)', ...
        trials, params);
    
    voxMeanTcs(:,:,iVox) = voxtc.meanTcs;
end
voxMeanTcs_dimHeaders = {'TR','cond','vox'};

%% plot mean tcs for all voxels
fig1 = figure('Position',[0 0 730 890]);
for iCond = 1:nConds
    condIdx = find(strcmp(trials.condNames{iCond}, voxtc.labels)); % iCond and condIdx might be different

    subplot(3,2,iCond)
    plot(frameWindow*TR, squeeze(voxMeanTcs(:,condIdx,:)));
    xlabel('time (s)')
    ylabel('BOLD amplitude')
    title(sprintf('Hemi %d, %s, %s', hemi, condNames{iCond}, voxDescrip));
    
    hold on
    plot(frameWindow*TR, mean(squeeze(voxMeanTcs(:,condIdx,:)),2),...
        'k','LineWidth',2)
    plot(frameWindow*TR, zeros(size(frameWindow)),'--k','LineWidth',1)
    
    ylim([-4 4])
end

% %% plot difference tcs
% for iCond = 2:nConds
%     fig2(iCond) = figure;
%     condDiff = squeeze(voxMeanTcs(:,iCond,:)-voxMeanTcs(:,1,:));
%     plot(frameWindow*TR, condDiff);
%     xlabel('time (s)')
%     ylabel('BOLD amplitude')
%     title(sprintf('Hemi %d, %s - %s, %s', ...
%         hemi, condNames{iCond}, condNames{1}, voxDescrip));
%     
%     hold on
%     plot(frameWindow*TR, mean(squeeze(voxMeanTcs(:,iCond,:)-voxMeanTcs(:,1,:)),2),...
%         'k','LineWidth',2)
%     plot(frameWindow*TR, zeros(size(frameWindow)),'--k','LineWidth',1)
% end

%% save data
if saveData
    save(analysisSavePath, 'hemi', 'voxelSelectionOption', 'varThresh', 'betaThresh', ...
        'betaCoefs','prop','group','groupNames','trials',...
        'frameWindow', 'TR', 'voxMeanTcs', 'voxMeanTcs_dimHeaders');
end

%% save figs
if saveFigs

    print(fig1,'-djpeg', sprintf('%s_%s', plotSavePath, datestr(now,'yyyymmdd')));

    
%     for iF = find(fig2)
%         print(fig2(iF),'-djpeg', sprintf('%s_%s-%s_%s', plotSavePath, condNames{iF}, condNames{1}, datestr(now,'yyyymmdd')));
%     end
end

