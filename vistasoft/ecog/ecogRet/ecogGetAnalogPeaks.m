function [tseries t peaks troughs] = ecogGetAnalogPeaks(thedir, analogChannel, anSampRate)
% [tseries t peaks troughs] = ecogGetAnalogPeaks(thedir, analogChannel, anSampRate)
%
% Example: [tseries t peaks troughs] = ecogGetAnalogPeaks;

% Check inputs - if they don't exist, use defaults
if notDefined('analogChannel'), analogChannel   = 'analog_2';   end
if notDefined('anSampRate'),    anSampRate      = 24414.1;      end
if notDefined('thedir'), thedir = fullfile(...
        '/biac3/wandell7/data/ECoG/ecog04/ecog',...
        'Ret_onoff_fullfield',...
        'ST07-20'...
        ); 
end

% Load analog channel
load(fullfile(thedir, analogChannel));
tseries = eval(analogChannel);
    
samps = 1:length(tseries);
t = samps/anSampRate;

thresh = max(tseries)/2;
tseriesThresh = tseries > thresh;
onsets  = diff(tseriesThresh) == 1;
offsets = diff(tseriesThresh) == -1;

peaks   = t(onsets);
troughs = t(offsets);

end

% plan for next time:

% finish this function (ecogGetAnalogPeaks)
% exrtact peaks
% count them (are they the number we expect from the expt?)
% align ecog channels to analog channels
% analyze data


% 1 impulse to photdiode approximately every 0.133 s, or 1/7.5 s, or 8
% frames (at 60 hz)

