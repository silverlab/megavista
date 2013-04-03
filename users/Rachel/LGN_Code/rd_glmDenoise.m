% GLM denoise

% let time be in TRs

%% Setup
% set paths
mvPath = 'ROIAnalysis/ROIX01/lgnROI1_multiVoxFigData.mat';
tSeriesPath = 'Inplane/Original/TSeries';
dataDim = '4D'; % dimensionality you want for the data, 2 = XYZ x time, 4 = XxYxZxtime

% scans = 2:3;
scans = 2:9; % M/P scans only
% slices = 1:numel(dir(sprintf('%s/Scan%d',tSeriesPath,scans(1))))-2; % ignore . and ..
slices = 9:13;
nSlices = numel(slices);
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
    designAllRuns(onsetFrames(frameInCond),iCond) = 1;
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
    switch dataDim
        case '4D'
            dataTemp = single(nan(nTRs,sqrt(xySize),sqrt(xySize),nSlices));
        case '2D'
            dataTemp = single(nan(nTRs,xySize*nSlices));
        otherwise
            error('dataDim not recognized')
    end
    for iSlice = 1:nSlices
        slice = slices(iSlice);
        fprintf('Slice %d \t%s\n', slice, datestr(now))
        tSeriesFile = sprintf('%s/Scan%d/tSeries%d.mat', tSeriesPath, scan, slice);
        tSeries = load(tSeriesFile);
        switch dataDim
            case '4D'
                dataTemp(:,:,:,iSlice) = reshape(tSeries.tSeries,nTRs,sqrt(xySize),sqrt(xySize)); % time x X x Y
            case '2D'
                xyzIdx = ((iSlice-1)*xySize+1):(iSlice*xySize);
                dataTemp(:,xyzIdx) = tSeries.tSeries;
            otherwise
                error('dataDim not recognized')
        end
    end
    switch dataDim
        case '4D'
            data{iRun} = shiftdim(dataTemp,1);
        case '2D'
            data{iRun} = dataTemp';
        otherwise
            error('dataDim not recognized')
    end
    if any(any(any(any(isnan(data{iRun})))))
        error('NaNs remain in the data for run %d. check data dimensions.',iRun)
    end
end

%% Check slices visually
for iRun = 1:nRuns
    fprintf('Run %d\n', iRun)
    for iSlice = 1:nSlices
        switch dataDim
            case '4D'
                imagesc(data{iRun}(:,:,iSlice,1))
            case '2D'
                xyzIdx = ((iSlice-1)*xySize+1):(iSlice*xySize);
                imagesc(reshape(data{iRun}(xyzIdx,1),sqrt(xySize),sqrt(xySize)))
            otherwise
                error('dataDim not recognized')
        end
        pause(.2)
    end
end

%% Run GLM denoise
runTime.start = datestr(now);
[results,denoiseddata] = GLMdenoisedata(design,data,stimDur,TR,[],[],[],'glmdenoisefigs1');
runTime.end = datestr(now);

% Save data
save('glmdenoise1.mat','design','data','stimDur','TR','results','denoiseddata','runTime')

%% Look at output for 2D dimensionality runs
thresh = prctile(results.meanvol(:),99)*.05;  % threshold for non-brain voxels, see opt.brainthresh 
bright = results.meanvol > thresh; 

if strcmp(dataDim,'2D')
    dataToPlot = results.noisepool;
    for iSlice = 1:nSlices
        xyzIdx = ((iSlice-1)*xySize+1):(iSlice*xySize);
        subplot(5,5,iSlice)
        dataInSlice = reshape(dataToPlot(xyzIdx,1),sqrt(xySize),sqrt(xySize));
        dataVolume(:,:,iSlice) = dataInSlice;
        imagesc(dataInSlice)
        pause(.2)
    end
end