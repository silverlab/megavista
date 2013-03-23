% GLM denoise

% let time be in TRs

%% Setup
% set paths
mvPath = 'ROIAnalysis/ROIX01/lgnROI1_multiVoxFigData.mat';
tSeriesPath = 'Inplane/Original/TSeries';

scans = 2:9; % M/P scans only
nSlices = numel(dir(sprintf('%s/Scan%d',tSeriesPath,scans(1))))-2; % ignore . and ..
sampleTSeries = load(sprintf('%s/Scan%d/tSeries1.mat',tSeriesPath,scans(1)));
xySize = size(sampleTSeries.tSeries,2); % time is 2nd dim

%% Prepare design matrix from mrVista multivoxel figData
mv = load(mvPath);

onsetFrames = mv.figData.trials.onsetFrames;
cond = mv.figData.trials.cond;
framesPerRun = mv.figData.trials.framesPerRun;
eventsPerBlock = mv.figData.params.eventsPerBlock;
TR = mv.figData.params.framePeriod;

conds = unique(cond(cond~=0)); % ignore the blank (0) condition
nConds = numel(conds);
nTRs = framesPerRun(1); % TRs per run
nRuns = numel(framesPerRun);
stimDur = eventsPerBlock*TR;

if nRuns~=numel(scans)
    error('Number of runs in mv data does not match number of scans selected.')
end

% Make design matrix (cell array, one cell for each run)
designAllRuns = zeros(nTRs*nRuns, nConds);
for iCond = 1:nConds
    frameInCond = cond==conds(iCond);
    designAllRuns(onsetFrames(frameInCond),iCond) = cond(frameInCond);
end

designByRun = reshape(designAllRuns',nConds,nTRs,nRuns);

design = cell(1,nRuns);
for iRun = 1:nRuns;
    design{iRun} = designByRun(:,:,iRun)';
end

%% Get the data from mrVista TSeries directories
for iRun = 1:nRuns
    fprintf('\nRun %d \t%s\n', iRun, datestr(now))
    scan = scans(iRun);
    data{iRun} = single(nan(nTRs,xySize*nSlices));
    for iSlice = 1:nSlices
        fprintf('Slice %d \t%s\n', iSlice, datestr(now))
        tSeriesFile = sprintf('%s/Scan%d/tSeries%d.mat', tSeriesPath, scan, iSlice);
        tSeries = load(tSeriesFile);
%         imagesc(reshape(tSeries.tSeries(1,:),128,128))
        xyzIdx = ((iSlice-1)*xySize+1):(iSlice*xySize);
        data{iRun}(:,xyzIdx) = tSeries.tSeries;
    end
    if any(any(isnan(data{iRun})))
        error(sprintf('NaNs remain in the data for run %d. check data dimensions.',iRun))
    end
end

%% Check slices visually
for iRun = 1:nRuns
    fprintf('Run %d\n', iRun)
    for iSlice = 1:nSlices
        xyzIdx = ((iSlice-1)*xySize+1):(iSlice*xySize);
        imagesc(reshape(data{iRun}(1,xyzIdx),128,128))
        pause(.2)
    end
end

%% Run GLM denoise
[results,denoiseddata] = GLMdenoisedata(design,data,stimDur,TR,[],[],[],'glmdenoisefigs');

%% Save data
save('glmdenoise.mat','design','data','tr','results','denoisedata')

