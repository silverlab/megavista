function [pwr pwroriginal] = ecogGetBarTimeSeries(subject, scanType, varargin)
% Extract time series from several retinotopy ECOG bar experiments
%   - Time series is the power at 15 Hz in 1-s time windows
%   - 96 time points x 64 electrodes x 3 runs
%
%  We will use these values to then solve a pRF model for each electrode


%% who what where
if ~exist('subject', 'var'),  subject  = 6;     end
if ~exist('scanType', 'var'), scanType = 'bar'; end

if exist('varargin', 'var')
    for ii = 1:2:length(varargin)
        switch lower(varargin{ii})
            case 'nelectrodes'
                nelectrodes = varargin{ii + 1};
            case 'overlap'
                overlap = varargin{ii + 1};
            case 'window'
                window = varargin{ii + 1};
            case 'foi'
                foi = varargin{ii + 1};
            case 'nframes'
                nframes = varargin{ii + 1};
            case  'nscans'
                nscans = varargin{ii + 1};
            case 'pwr'
                pwr = varargin{ii + 1};
            case  'parentdir'
                parentdir = varargin{ii + 1};
            case 'savedir'
                saveDir = varargin{ii + 1};            
            case 'savedata'
                saveData = varargin{ii + 1};             
                
        end
    end
end

switch subject
    case 4
        runs   = 2:4;        
        ecogdir = '/biac3/wandell7/data/ECoG/ecog04/ecog/eCOGpRF/eCOGpRF';
        if ~exist('nelectrodes', 'var'), nelectrodes = 64; end
    case 6
        runs   = 1:5;
        ecogdir = '/biac3/wandell7/data/ECoG/ecog06/ecog/eCOGpRF';
        if ~exist('nelectrodes', 'var'), nelectrodes = 84; end
        
    case 8
        runs   = 1:5;
        ecogdir = '/biac3/wandell7/data/ECoG/ecog08/ecog/eCOGpRF';
        if ~exist('nelectrodes', 'var'), nelectrodes = 64; end

end

theelectrodes   = 1:nelectrodes;
if ~exist('overlap', 'var'),     overlap         = 0;                                              end
if ~exist('window', 'var'),      window          = 1;                                               end
if ~exist('foi', 'var'),         foi             = 15;                                              end % frequencies of interest
if ~exist('nframes', 'var'),     nframes         = 96;                                              end
if ~exist('nscans', 'var'),      nscans          = length(runs);                                    end
if ~exist('pwr', 'var'),         pwr             = zeros(nscans, nframes, nelectrodes);             end
if ~exist('parentdir', 'var'),   parentdir       = ecogdir;                                         end
if ~exist('saveDir', 'var'),     saveDir         = fullfile(parentdir,'Inplane/Original/TSeries/'); end
if ~exist('saveData', 'var'),    saveData        = false;                                           end


%% *****************************************************
% Extract the time series for all electrodes in all runs
% ******************************************************

% Wait bar
waitHandle = waitbar(0,'Extracting tSeries.  Please wait...');

for electrode = theelectrodes

    for r = 1:nscans
        run = runs(r);
        [startTimes, pwr(r, :, electrode)] = ecogPlotExtractedTimeSeries(subject, scanType, run, electrode, overlap, window, foi);                                    
        if ~isequal(nframes, length(startTimes)), 
            warning('Length of startimes for run %d. electrode %d = %d, not 96', run, electrode, length(startTimes))
        end
    end

 
waitbar(electrode/length(theelectrodes))
end
close(waitHandle);

%% *****************************************************
% Subtract out baseline activity
% ******************************************************
%  (i.e., subtract the mean signal during stimulus blanks)

% define the blank frames
switch subject
    case 4
        a = 13; % blank onset
        b = 24; % blank offset
        c = 24; % stimulus duration (ie interblank interval)
    case 6
        a = 19; % blank onset
        b = 24; % blank offset
        c = 24; % stimulus duration (ie interblank interval)
end
blankFrames = [a:b (a:b)+c (a:b)+2*c (a:b) + 3*c];
        
% make a new matrix with the signals only during blanks
blanks      = pwr(:, blankFrames, :); 
meanBlanks  = mean(blanks, 2);
meanBlanks  = repmat(meanBlanks, [1 nframes 1]);

pwroriginal = pwr;
pwr         = pwr - meanBlanks;

%% *****************************************************
% Save time series into INPLANE structure
% ******************************************************
if saveData
    for r = 1:nscans
        tSeries = zeros(nframes, nelectrodes);
        tSeries(1:nframes, 1:nelectrodes) = pwr(r, :, :); %#ok<NASGU>
        thefile = fullfile(saveDir,  sprintf('Scan%d',r), 'tSeries1.mat');
        save(thefile, 'tSeries');
        
    end
    
end

%% Check
%   Cross correlate the time series across runs to make sure start
%   times are aligned
%
%     figure;
%     suptitle(sprintf('electrode: %d', electrode))
% 
%     subplot(2,2, 1)
%     [c1, lags] = xcorr(pwr{2}, pwr{3}, 10);
%     plot(lags, c1, 'x-'); hold on
%     plot([0 0], [0 max(c1)], 'k--')
% 
%     subplot(2,2, 2)
%     [c1, lags] = xcorr(pwr{2}, pwr{4}, 10);
%     plot(lags, c1, 'x-');hold on
%     plot([0 0], [0 max(c1)], 'k--')
% 
%     subplot(2,2, 3)
%     [c1, lags] = xcorr(pwr{3}, pwr{4}, 10);
%     plot(lags, c1, 'x-');hold on
%     plot([0 0], [0 max(c1)], 'k--')