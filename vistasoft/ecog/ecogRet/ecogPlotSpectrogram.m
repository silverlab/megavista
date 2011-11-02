% Script to plot spectrogram data from ecog subject4
% parentdir: /biac3/wandell7/data/ECoG/ecog04/ecog
%   Ret_bar:                scans 15, 17, 19, 21
%   Ret_onoff_fullfield:    scans 16, 18, 20

if notDefined('scanType'),      scanType        = 'bar';    end 
if notDefined('run'),           run             = 2;        end 
if notDefined('theelectrodes'), theelectrodes   = 14;       end
if notDefined('overlap'),       overlap         = .9;       end % fraction
if notDefined('window'),        window          =  1;       end % seconds
if nargout < 1, doPlot = true; else doPlot = false;         end




% navigate
parentdir = '/biac3/wandell7/data/ECoG/ecog04/ecog';
cd(parentdir);

barscans    = [15, 17, 19, 21];
onoffscans  = [16, 18, 20];
mtloc       = [22, 23];  % note that no electrodes covered hMT+ in this patient

starts.bar = [-2.5 23.5 8.5 20.4];
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

samplerate = 3051.76;

% spectrogram parameters
w = round(window * samplerate);
noverlap = round(overlap * w);



% Plot each data set in a big 8 x 8 grid
figure;
nplots = ceil(sqrt(length(theelectrodes)));

for ii = 1:length(theelectrodes)
    thiselectrode = theelectrodes(ii);
    
    subplot(nplots,nplots,ii);

    x = eval(sprintf('gdat_%d',thiselectrode));
    t = (1:length(x)) / samplerate;
    
    inds = t > startclip & t < endclip;
    x = x(inds); 
    
    F = 0:.1:150;
    [y,f,t,p] = spectrogram(double(x),w,noverlap,F,samplerate,'yaxis');
    % [S,F,T,P] = SPECTROGRAM(X,WINDOW,NOVERLAP,F,Fs)

    % NOTE: This is the same as calling SPECTROGRAM with no outputs.
    surf(t,f,10*log10(abs(p)),'EdgeColor','none');
    axis xy; axis tight; colormap(jet); view(0,90);
    
    c = get(gca, 'clim');
    caxis([0 max(c)]);
    
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
end