function anal = er_chopTSeries(view,roi,scans,varargin);% anal = er_chopTSeries(view,[roi],[scans],[options]);%% Concatenates tSeries from the selected scans together,% chops up according to the assigned parfiles, and returns% an analysis struct with the following fields:%%   wholeTc: vector of whole time course, concatenated across scans,%            for selected scans, voxels%   allTcs:  3D matrix of time courses for every trial. The rows%            are different time points, the columns are different%            trials, and the slices (z dim) are different conditions.%            As with other trials, the data is taken from the specified%            time window, incl. prestim frames.%   meanTcs: matrix of mean time courses for each condition. Rows %            are different time points, columns are different conds.%   sems:    corresponding standard errors of the mean for meanTcs.%   timeWindow: vector specifying the time in seconds, relative to the%               trial onset, from which each trial / mean trial time %               course is taken. [default is -4:16].%   peakPeriod: time, in seconds, where the HRF is expected to peak.%               This will be used for t-test and amplitude results below.%               [default is 8:14].%   bslPeriod:  time, in seconds, to consider as a baseline period. %               [default is 2:6].%   amps:       Estimated amplitudes for each trial, taken%               as the mean amplitude during the peak period%               minus the mean amplitude during the baseline period.%               This is a 2D matrix where rows are different trials%               and columns are different conditions.%   relamps:    relative fMRI amplitudes (e.g. dot products with the%               mean time course) for each trial, in the same format%               as amps. These should be less sensitive to the choice%               of peak and baseline periods than amps, but may not be%               accurate if different conditions have fundamentally%               different response shapes (e.g., if there's a baseline%               period where everything is decreasing and all other %               conditions are increasing.)%   Hs:         1 x nConds binary vector reflecting whether%               each condition had a mean significant activation%               during peak relative to baseline periods%               (one-sided t-test alpha = 0.05 by default but%               may be entered as an optional argument).%   ps:         Corresponding p-values for the t-tests for Hs.%   SNR:        Mean signal to noise ratio for all trials.%               (mean signal for peakPeriod - bslPeriod)/(stdev bslPeriod)%   SNRdb:      Expression of SNR as decibels: 20 * log10(SNR).%% Many params can be entered as optional arguments. In these cases,% call them with the form ...'arg name',[value],.... The fields% that can be entered are: timeWindow, peakPeriod, bslPeriod, alpha.%% Further options:%   normBsl,[1 or 0]:   if 1, will align trials during the baseline%                       period [default is 1].%   alpha,[val]:        alpha value for t-tests [default 0.05].%   onsetDelta,[val]:   automatically shift the onsets in parfiles%                       relative to the time course by this amount%                       (e.g. to compensate for HRF rise time).%   'waitbar':          put up a waitbar instead of showing progress in%                       the command line.%% 06/17/04 ras: wrote it.% 07/28/04 ras: clarified annotation.% 10/17/04 ras: changed default params to be nicer for my ER stuff.% 05/25/05 ras: fixed calculation of relative amplitudes.global dataTYPES;if ieNotDefined('roi')    rois = viewGet(view,'rois');    selRoi = viewGet(view,'selectedroi');    roi = rois(selRoi);endroi = tc_roiStruct(view,roi);coords = roi.coords;dt = viewGet(view,'curdt');if ieNotDefined('scans')    [scans dt] = er_getScanGroup(view);    view = viewSet(view,'curdt',dt);end%%%%% params/defaults %%%%%params = er_getParams(view,scans(1)); % get from dataTYPESnormBsl = params.normBsl;       % flag to zero baseline or notalpha = params.alpha;           % threshold for significant activationsbslPeriod = params.bslPeriod;   % period to use as baseline in t-tests, in secondspeakPeriod = params.peakPeriod; % period to look for peaks in t-tests, in secondstimeWindow = params.timeWindow; % seconds relative to trial onset to take for each trialonsetDelta = params.onsetDelta; % # secs to shift onsets in parfiles, relative to time coursesnrConds = params.snrConds;     % For calculating SNR, which conditions to use (if empty, use all)waitbarFlag = 0;        % flag to show a graphical waitbar to show load progressfindPeaksFlag = 0;      % when computing amps, find peak period separately for each condbarebones = 0;          % if 1, will do only a minimal analysis -- no SNR calculation, etc.extTSeries = [];        % if nonempty, will use this as the time series instead of loading it.TR = dataTYPES(dt).scanParams(scans(1)).framePeriod;%%%%% some params may have been initialized to emptyif isempty(alpha)       alpha = 0.05;           endif isempty(bslPeriod)   bslPeriod = [-4:0];     endif isempty(peakPeriod)  peakPeriod = [4:12];    endif isempty(timeWindow)  timeWindow = [-8:22];   endif isempty(onsetDelta)  onsetDelta = 0;         end%%%%% parse the options %%%%%varargin = unNestCell(varargin);for i = 1:length(varargin)    if ischar(varargin{i})        switch lower(varargin{i})            case 'normbsl', normBsl = varargin{i+1};            case 'alpha', alpha = varargin{i+1};            case 'peakperiod', peakPeriod = varargin{i+1};            case 'timewindow', timeWindow = varargin{i+1};            case 'scans', scans = varargin{i+1};            case 'dt', dt = varargin{i+1};            case 'onsetdelta', onsetDelta = varargin{i+1};            case 'waitbar', waitbarFlag = 1;            case 'tseries', extTSeries = varargin{i+1};             case 'snrconds', snrConds = varargin{i+1};            case 'waitbar', waitbarFlag = 1;            case 'findpeaks', findPeaksFlag = 1;                            otherwise, % ignore        end    endend%%%%% concatenate tSeries from selected scans (if not passed in)if isempty(extTSeries)      % load it    wholeTc = [];	if waitbarFlag        if length(scans) > 1           textstring=sprintf('Loading tSeries from %s scans %d-%d...',dataTYPES(dt).name,min(scans),max(scans));           hwait = waitbar(0,textstring);       end   else        fprintf('Loading tSeries from selected scans ... \t');            end		for s = scans        raw = ~(detrendFlag(view,s));        % subt = meanTSeries(view,s,coords);        tS = voxelTSeries(view,coords,s,raw);        subt = mean(tS')';        wholeTc = [wholeTc subt'];                if waitbarFlag            if length(scans) > 1                waitbar(find(scans==s)/length(scans),hwait);            end        else            fprintf('%i ',s);        end    end		if waitbarFlag        if length(scans) > 1        close(hwait);       end    else        fprintf('\n');    endelse                        % it's been passed in as an option    wholeTc = extTSeries;end%%%%% get parfile info, if it's not passed in in varargintrials = er_concatParfiles(view,scans);trials.onsetSecs = trials.onsetSecs + onsetDelta;trials.onsetFrames = trials.onsetFrames + onsetDelta/TR;%%%%% get nConds from trials structcondNums = unique(trials.cond(trials.cond >= 0));nConds = length(condNums);%%%%% get a set of label names, if they were specified in the parfilesfor i = 1:nConds    ind = find(trials.cond==condNums(i));    labels{i} = trials.label{ind(1)};end%%%%% convert params expressed in secs into framestimeWindow = timeWindow(mod(timeWindow,TR)==0);frameWindow = unique(round(timeWindow./TR));prestim = -1 * frameWindow(1);peakFrames = unique(round(peakPeriod./TR));bslFrames = unique(round(bslPeriod./TR));peakFrames = find(ismember(frameWindow,peakFrames));bslFrames = find(ismember(frameWindow,bslFrames));%%%%% remove trials at the very end of a scan, without%%%%% enough data to fill the time windowcutOff = find(trials.onsetFrames+frameWindow(end) > length(wholeTc));if ~isempty(cutOff)    keep = setdiff(1:length(trials.cond),cutOff);    trials.cond = trials.cond(keep);    trials.onsetFrames = trials.onsetFrames(keep);    trials.onsetSecs = trials.onsetSecs(keep);end%%%%% build allTcs matrix of time points x trials x  conditions%%%%% take (frameWindow) secs from each trialallTcs = [];for i = 1:nConds   cond = condNums(i);   ind = find(trials.cond==cond);   for j = 1:length(ind)       tstart = max(trials.onsetFrames(ind(j)),1);       tend = min([tstart+frameWindow(end),length(wholeTc)]);       rng = tstart:tend;       % add prestim       if tstart < prestim+1           % for 1st trial, no baseline available -- set to 0           allTcs(:,j,i) = [zeros(1,prestim) wholeTc(rng)]';       else           % augment the range by previous [prestim] frames           fullrng = rng(1)-prestim:rng(end);           allTcs(1:length(fullrng),j,i) = wholeTc(fullrng)';          end              % remove baseline estimate, if selected       if normBsl           % estimate DC offset by prestim baseline vals           DC = nanmean(allTcs(bslFrames,j,i));           allTcs(:,j,i) = allTcs(:,j,i) - DC;       end   end end %%%%% find 'empty' trials, set to NaNs% (Empty trials will result if some conditions have more% trials than others -- in the conditions w/ fewer trials,% the allTcs matrix will be padded with 0s to keep it a cube).for y = 1:size(allTcs,2)    for z = 1:size(allTcs,3)        if all(allTcs(:,y,z)==0)            allTcs(:,y,z) = NaN;        end    endend%%%%% get mean time courses, sems for each conditionmeanTcs = zeros(length(frameWindow),nConds);sems = zeros(length(frameWindow),nConds);maxNTrials = size(allTcs,2);for i = 1:nConds    nTrials = size(allTcs,2) - sum(any(isnan(allTcs(:,:,i))));    if maxNTrials > 1        meanTcs(:,i) = nanmean(allTcs(:,:,i)')';        sems(:,i) = nanstd(allTcs(:,:,i)')' ./ sqrt(nTrials);    else        meanTcs(:,i) = allTcs(:,:,i);    endend%%%%% calc amplitudes, do t-tests of post-baseline v. baselineHs = NaN*ones(1,nConds);for i = 1:nConds    if findPeaksFlag==1        % find the peak separately for        % each condition        maxVal = max(meanTcs(2:end-1,i));        maxT = find(meanTcs(:,i)==maxVal);        peak = allTcs(maxT-1:maxT+1,:,i);        bsl = allTcs(bslFrames,:,i);    else        bsl = allTcs(bslFrames,:,i);        peak = allTcs(peakFrames,:,i);    end    amps(:,i) = (nanmean(peak) - nanmean(bsl))';    if ~barebones        [Hs(i) ps(i)] = ttest2(bsl(:),peak(:),alpha,-1);    endend%%%%% compute Signal-to-Noise Ratioif isempty(snrConds)    snrConds = find(condNums > 0);else    % index into condNumbers (e.g. so you can select 0)    snrConds = find(ismember(condNums,snrConds));endallBsl = meanTcs(bslFrames,snrConds);allPk = meanTcs(peakFrames,snrConds);SNR = abs(mean(allPk(:)) - mean(allBsl(:))) / std(allBsl(:));%%%%% compute dot-product relative amplitudes % the resulting matrix will be of size% nTrials x nConds%relamps = er_relamps(allTcs);%%%%% assign everything to the output structanal.wholeTc = wholeTc;anal.allTcs = allTcs;anal.meanTcs = meanTcs;anal.sems = sems;anal.labels = labels;anal.timeWindow = timeWindow;anal.peakPeriod = peakPeriod(mod(peakPeriod,TR)==0);anal.bslPeriod = bslPeriod(mod(bslPeriod,TR)==0);anal.condNums = condNums;anal.Hs = Hs;anal.ps = ps;anal.amps = amps;%anal.relamps = relamps;anal.SNR = SNR;anal.SNRdb = 20 * log10(SNR);return