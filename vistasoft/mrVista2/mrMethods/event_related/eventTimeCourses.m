function anal = eventTimeCourses(tSeries,stim,params,varargin);
% anal = eventTimeCourses(tSeries,stim,params,[options]);
%
% View-independent verson of er_chopTSeries.
% chops up entered tSeries according to the assigned parfiles.
%
% Inputs are tSeries (matrix where rows are time points, cols are
% different tSeries, say from diff't rois/voxels), and stim
% (a struct obtained from er_concatParfiles, containing design matrix
% information).
%
% returns an analysis struct with the following fields:
%
%   wholeTc: vector of whole time course, concatenated across scans,
%            for selected scans, voxels
%   allTcs:  3D matrix of time courses for every trial. The rows
%            are different time points, the columns are different
%            stim, and the slices (z dim) are different conditions.
%            As with other stim, the data is taken from the specified
%            time window, incl. prestim frames.
%   meanTcs: matrix of mean time courses for each condition. Rows 
%            are different time points, columns are different conds.
%   sems:    corresponding standard errors of the mean for meanTcs.
%   timeWindow: vector specifying the time in seconds, relative to the
%               trial onset, from which each trial / mean trial time 
%               course is taken. [default is -4:16].
%   peakPeriod: time, in seconds, where the HRF is expected to peak.
%               This will be used for t-test and amplitude results below.
%               [default is 8:14].
%   bslPeriod:  time, in seconds, to consider as a baseline period. 
%               [default is 2:6].
%   amps:       Estimated amplitudes for each trial, taken
%               as the mean amplitude during the peak period
%               minus the mean amplitude during the baseline period.
%               This is a 2D matrix where rows are different stim
%               and columns are different conditions.
%   relamps:    relative fMRI amplitudes (e.g. dot products with the
%               mean time course) for each trial, in the same format
%               as amps. These should be less sensitive to the choice
%               of peak and baseline periods than amps, but may not be
%               accurate if different conditions have fundamentally
%               different response shapes (e.g., if there's a baseline
%               period where everything is decreasing and all other 
%               conditions are increasing.)
%   Hs:         1 x nConds binary vector reflecting whether
%               each condition had a mean significant activation
%               during peak relative to baseline periods
%               (one-sided t-test alpha = 0.05 by default but
%               may be entered as an optional argument).
%   ps:         Corresponding p-values for the t-tests for Hs.
%   SNR:        Mean signal to noise ratio for all stim.
%               (mean signal for peakPeriod - bslPeriod)/(stdev bslPeriod)
%   SNRdb:      Expression of SNR as decibels: 20 * log10(SNR).
%
% Many params can be entered as optional arguments. In these cases,
% call them with the form ...'arg name',[value],.... The fields
% that can be entered are: timeWindow, peakPeriod, bslPeriod, alpha.
%
% Further options:
%   barebones:          do only a minimal analysis, extracting
%                       mean time courses, amplitudes, and SEMs.
%                       This is useful for across-voxel analyses.
%
%   normBsl,[1 or 0]:   if 1, will align stim during the baseline
%                       period [default is 1].
%   alpha,[val]:        alpha value for t-tests [default 0.05].
%   onsetDelta,[val]:   automatically shift the onsets in parfiles
%                       relative to the time course by this amount
%                       (e.g. to compensate for HRF rise time).
%   'waitbar':          put up a waitbar instead of showing progress in
%                       the command line.
%   'findPeaks':        when calculating response amplitudes, figure
%                       out the peak amplitude separately for each 
%                       condition, taking the peak and surrounding 2 points.
%   [params struct]:    input a struct containing all of these
%                       params. See er_getParams.
%
% 06/17/04 ras: wrote it.
% 07/28/04 ras: clarified annotation.
% 01/25/05 ras: can now input params struct.
% 05/25/05 ras: fixed calculation of relative amplitudes.
% 08/10/05 ras: imported into mrVista 2.0 as eventTimeCourses.
if notDefined('params'),    params = eventParamsDefault;    end

%%%%% params/defaults %%%%%
barebones = 0;                  % if 0, do full analysis; if 1, do minimal analysis
normBsl = params.normBsl;       % flag to zero baseline or not
alpha = params.alpha;           % threshold for significant activations
bslPeriod = params.bslPeriod;   % period to use as baseline in t-tests, in seconds
peakPeriod = params.peakPeriod; % period to look for peaks in t-tests, in seconds
timeWindow = params.timeWindow; % seconds relative to trial onset to take for each trial
onsetDelta = params.onsetDelta; % # secs to shift onsets in parfiles, relative to time course
snrConds = params.snrConds;     % For calculating SNR, which conditions to use (if empty, use all)
waitbarFlag = 0;        % flag to show a graphical waitbar to show load progress
findPeaksFlag = 0;      % when computing amps, find peak period separately for each cond
TR = stim.TR;

%%%%% parse the options %%%%%
varargin = unNestCell(varargin);
for i = 1:length(varargin)
    if isstruct(varargin{i})
        % assume it's a params struct
        names = fieldnames(varargin{i});
        for j = 1:length(names)
            cmd = sprintf('%s = varargin{i}.%s;',names{j},names{j});
            eval(cmd);
        end
            
    elseif ischar(varargin{i})
        switch lower(varargin{i})
        case 'barebones', barebones = 1;
        case 'normbsl', normBsl = varargin{i+1};
        case 'alpha', alpha = varargin{i+1};
        case 'peakperiod', peakPeriod = varargin{i+1};
        case 'bslperiod', bslPeriod = varargin{i+1};
        case 'timewindow', timeWindow = varargin{i+1};
        case 'onsetdelta', onsetDelta = varargin{i+1};
        case 'snrconds', snrConds = varargin{i+1};
        case 'waitbar', waitbarFlag = 1;
        case 'findpeaks', findPeaksFlag = 1;
        otherwise, % ignore
        end
    end
end

%%%%% account for format of time series
% in this code compared to elsewhere (dumb, I know, but there's a reason)
if size(tSeries,2)==1 & size(tSeries,1) > 1 % column vector
    wholeTc = tSeries'; % flip the col vector around
elseif (size(tSeries,1)>1) & (size(tSeries,2)>1)
    % what the heck, let's go recursively on the columns
    for i = 1:size(tSeries,2)
        anal(i) = eventTimeCourses(tSeries(:,i),stim,params,varargin);
    end
    return
else
    wholeTc = tSeries;
end
clear tSeries;

% account for onset shift
if mod(onsetDelta,TR) ~= 0
    % ensure we shift by an integer # of frames
    onsetDelta = TR * round(onsetDelta/TR);
end
stim.onsetSecs = stim.onsetSecs + onsetDelta;
stim.onsetFrames = stim.onsetFrames + onsetDelta/TR;

%%%%% get nConds from stim struct
condNums = unique(stim.cond(stim.cond >= 0)); 
nConds = length(condNums);

%%%%% get a set of label names, if they were specified in the parfiles
for i = 1:nConds
    ind = find(stim.cond==condNums(i));
    labels{i} = stim.label{ind(1)};
end

%%%%% convert params expressed in secs into frames
frameWindow = unique(round(timeWindow./TR));
prestim = -1 * frameWindow(1);
peakFrames = unique(round(peakPeriod./TR));
bslFrames = unique(round(bslPeriod./TR));
peakFrames = find(ismember(frameWindow,peakFrames));
bslFrames = find(ismember(frameWindow,bslFrames));

%%%%% remove stim at the very end of a scan, without
%%%%% enough data to fill the time window
cutOff = find(stim.onsetFrames+frameWindow(end) > length(wholeTc));
if ~isempty(cutOff)
    keep = setdiff(1:length(stim.cond),cutOff);
    stim.cond = stim.cond(keep);
    stim.onsetFrames = stim.onsetFrames(keep);
    stim.onsetSecs = stim.onsetSecs(keep);
end


%%%%% build allTcs matrix of time points x stim x  conditions
%%%%% take (frameWindow) secs from each trial
allTcs = [];

for i = 1:nConds
   cond = condNums(i);
   ind = find(stim.cond==cond);
   for j = 1:length(ind)
       tstart = max(stim.onsetFrames(ind(j)),1);
       tend = min([tstart+frameWindow(end),length(wholeTc)]);
       rng = tstart:tend;

       % add prestim
       if tstart < prestim+1
           % for 1st trial, no baseline available -- set to 0
           allTcs(:,j,i) = [zeros(1,prestim) wholeTc(rng)]';
       else
           % augment the range by previous [prestim] frames
           fullrng = rng(1)-prestim:rng(end);
           allTcs(1:length(fullrng),j,i) = wholeTc(fullrng)';   
       end
       
       % remove baseline estimate, if selected
       if normBsl
           % estimate DC offset by prestim baseline vals
           DC = nanmean(allTcs(bslFrames,j,i));
           allTcs(:,j,i) = allTcs(:,j,i) - DC;
       end
   end 
end 

%%%%% find 'empty' stim, set to NaNs
% (Empty stim will result if some conditions have more
% stim than others -- in the conditions w/ fewer stim,
% the allTcs matrix will be padded with 0s to keep it a cube).
for y = 1:size(allTcs,2)
    for z = 1:size(allTcs,3)
        if all(allTcs(:,y,z)==0)
            allTcs(:,y,z) = NaN;
        end
    end
end

%%%%% get mean time courses, sems for each condition
meanTcs = zeros(length(frameWindow),nConds);
sems = zeros(length(frameWindow),nConds);
maxNTrials = size(allTcs,2);

for i = 1:nConds
    nTrials = size(allTcs,2) - sum(any(isnan(allTcs(:,:,i))));
    if maxNTrials > 1
        meanTcs(:,i) = nanmean(allTcs(:,:,i)')';
        sems(:,i) = nanstd(allTcs(:,:,i)')' ./ sqrt(nTrials);
    else
        meanTcs(:,i) = allTcs(:,:,i);
    end
end

%%%%% calc amplitudes, do t-tests of post-baseline v. baseline
Hs = NaN*ones(1,nConds);

for i = 1:nConds
    if findPeaksFlag==1
        % find the peak separately for
        % each condition
        maxVal = max(meanTcs(2:end-1,i));
        maxT = find(meanTcs(:,i)==maxVal);
        peak = allTcs(maxT-1:maxT+1,:,i);
        bsl = allTcs(bslFrames,:,i);
    else
        bsl = allTcs(bslFrames,:,i);
        peak = allTcs(peakFrames,:,i);
    end
    amps(:,i) = (mean(peak) - mean(bsl))';

    if ~barebones
        [Hs(i) ps(i)] = ttest2(bsl(:),peak(:),alpha,-1);
    end
end

%%%%% compute Signal-to-Noise Ratio
if ~barebones
    if isempty(snrConds)
        snrConds = find(condNums > 0);
    else
        % index into condNumbers (e.g. so you can select 0)
        snrConds = find(ismember(condNums,snrConds));
    end
    
	allBsl = meanTcs(bslFrames,snrConds);
	allPk = meanTcs(peakFrames,snrConds);
	SNR = abs(mean(allPk(:)) - mean(allBsl(:))) / std(allBsl(:));
end

%%%%% compute relamps 
% the resulting matrix will be of size
% nTrials x nConds
if ~barebones
%	relamps = er_relamps(allTcs);
end

%%%%% assign everything to the output struct
anal.wholeTc = wholeTc;
anal.allTcs = allTcs;
anal.meanTcs = meanTcs;
anal.sems = sems;
anal.labels = labels;
anal.timeWindow = timeWindow(mod(timeWindow,TR)==0);
anal.peakPeriod = peakPeriod(mod(peakPeriod,TR)==0);
anal.bslPeriod = bslPeriod(mod(bslPeriod,TR)==0);
anal.condNums = condNums;
anal.amps = amps;

if ~barebones
	anal.Hs = Hs;
	anal.ps = ps;
	% anal.relamps = relamps;
	anal.SNR = SNR;
	anal.SNRdb = 20 * log10(SNR);
end

return
