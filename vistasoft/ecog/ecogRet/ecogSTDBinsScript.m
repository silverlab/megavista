
% ecogSTDBinsScript

% Script to plot 64-channel data from ecog subject4
% parentdir: /biac3/wandell7/data/ECoG/ecog04/ecog
%   Ret_bar:                scans 15, 17, 19, 21
%   Ret_onoff_fullfield:    scans 16, 18, 20

if notDefined('scanType'),      scanType        = 'bar';    end
if notDefined('run'),           run             = 3;        end
if notDefined('theelectrodes'), theelectrodes   = 25:29;    end  % 11:15
if notDefined('overlap'),       overlap         = .5;       end



% navigate
parentdir = '/biac3/wandell7/data/ECoG/ecog06/ecog';
cd(parentdir);

ecogPlotExtractedTimeSeries(parentdir, scanType, run, theelectrodes, overlap)

barscans    = [15, 17, 19, 21];
onoffscans  = [16, 18, 20];
mtloc       = [22, 23];  % note that no electrodes covered hMT+ in this patient

starts.bar = [0 23.5 8.5 20.4];
starts.onoff = [0 0 0 0];
starts.mtloc = [0 0 0 0];


ends.bar = starts.bar + 96;
ends.onoff = [500 500 500 500];
ends.mtloc = [500 500 500 500];

% find the dir and run
switch scanType
    case  'bar'
        thedir = 'Ret_bar';
        therun = barscans(run);
    case 'onoff'
        thedir = 'Ret_onoff_fullfield';
        therun = onoffscans(run);
    case 'mtloc'
        thedir = 'MTloc';
        therun = mtloc(run);
end
therun = ['ST07-' num2str(therun)];

% Approximate start / end (in s)?
startclip = starts.(scanType)(run); %seconds
endclip   = ends.(scanType)(run); %seconds

% Load data from specified channels
for ii = theelectrodes;
    thechannel = sprintf('gdat_%d', ii);
    load(fullfile(thedir, therun, thechannel));
end

% Load analog channel
anChan = 'analog_2';
load(fullfile(thedir, therun, anChan));
anSampRate = 24414.1;
samps = 1:length(eval(anChan));
samptimes = samps/anSampRate;


% Plot each data set in a big 8 x 8 grid
figure;
nplots = ceil(sqrt(length(theelectrodes)));

for ii = 1:length(theelectrodes)
    
    thiselectrode = theelectrodes(ii);
    
    subplot(nplots,nplots,ii);

    whichdata = eval(sprintf('gdat_%d',thiselectrode));

    [s, startTimes, p] = ecogSTDBins(whichdata, 1, overlap);

    inds = startTimes > startclip & startTimes < endclip;

    plot(startTimes(inds), p(inds));  hold on
    %plot(startTimes(inds), s(inds), 'r'); hold on
    
    inds = samptimes > startclip -1 & samptimes < endclip + 1;
    
    amp = -eval(anChan)*20;
    plot(samptimes(inds),amp(inds),'g');
    %plot(samptimes,[diff(eval(anChan)*20) 0],'kx-');
    axis tight; 
    grid on;
    
    title(sprintf('Electrode %d; Run %s', thiselectrode, therun))
end