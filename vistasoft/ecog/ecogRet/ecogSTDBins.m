function [stanDev, startTimes, amp, ph] = ecogSTDBins(tseries, windowSize, overlap, samplerate, foi, startclip)
%   Return the stdev, or amplitdue at a specicied frequency, of a moving window of an ECOG
%
% [stanDev, startTimes, amp, ph] = ecogSTDBins(tseries, [windowSize], [overlap], [samplerate])
%
%   tseries:    the raw ECOG time series
%   windowSize: window size in s from which to calculate std ([default = 0.1])
%   plotit:     if true, make a plot [default = false]
%   overlap:    the fractional overlap between successive windows ([default = 0.5])
%   samplerate: sample rate of the raw data in hz [default = 3051.76]
%                       where did this number come from? is it always the
%                       same?
%   % foi:      frequency of interest for extracting power
%
% Example 1:
%   [s,t] = ecogSTDBins([], 0.5); plot(t, s);
%
% Example 2:
%   [s,t, p] = ecogSTDBins([], 1, 0.9); plot(t, s);
%
% Default values if inputs are missing
if notDefined('tseries'),       error('Need t-series to analyze'); end
if notDefined('windowSize'),    windowSize  = 0.1;      end % in sec
if notDefined('plotit'),        plotit      = false;    end % boolean
if notDefined('overlap'),       overlap     = 0.5;      end % (0, 1)
if notDefined('samplerate'),    samplerate  = 3051.76;  end % hz
if notDefined('startclip'),     startclip   = 0;        end % in sec

% length of time series in frames
l=length(tseries);

% time
t = (1:l) / samplerate;

% first time point
startFrame = find(t-startclip > 0, 1);

% binsize in frames
binsize = samplerate*windowSize;

% binstep in frames
binstep = binsize*(1-overlap);

% start bins at which frame numbers?
startBins = startFrame:binstep:l-binsize;

% start bins at which times (in s)?
startTimes = startBins / samplerate;

% initialize the output args
stanDev = zeros(length(startBins), 1);
amp     = zeros(length(startBins), length(foi));
ph      = amp;

% start the counter
binNum = 1;

for ii = startBins
    thisBin = round(ii:(ii+binsize));
    [amp(binNum,:) ph(binNum,:)] = getFsignal(tseries(thisBin), samplerate, foi);
    binNum=binNum+1;
end

end

function [amp ph] = getFsignal(tseries, Fs, foi)

if notDefined('foi'),
    foi = 15; %frequency of interest
end

amp = zeros(1, length(foi));
ph  = zeros(1, length(foi));

L = length(tseries);
NFFT = 2^nextpow2(L);
Y = fft(tseries,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2);
theamps  = 2*abs(Y(1:NFFT/2));
thephase = angle(Y(1:NFFT/2));

for ii = 1:length(foi)
    [~, theind] = min(abs(f-foi(ii)));
    amp(ii) = theamps(theind);
    ph(ii)  = thephase(theind);
end

end