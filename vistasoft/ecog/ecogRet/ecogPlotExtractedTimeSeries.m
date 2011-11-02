function [startTimes, amps, ph] = ecogPlotExtractedTimeSeries(subject,scanType, run, theelectrodes, overlap, thewindow, foi)
%  [startTimes, amps, ph] = ecogPlotExtractedTimeSeries(subject,scanType, run, ...
%                       theelectrodes, overlap, thewindow, foi)

% Script to plot/extract data from ecog subjects. The script reads the raw
% files and extracts amplitudes at specified frequencies in amps moving
% window.
%
% If you add more subejcts or more experiments, please update this code.

%% Define variabels
if notDefined('subject'),       subject         = 6;        end 
if notDefined('scanType'),      scanType        = 'bar';    end 
if notDefined('run'),           run             = 1;        end 
if notDefined('theelectrodes'), theelectrodes   = 11:16;    end
if notDefined('overlap'),       overlap         = .5;       end % fraction
if notDefined('thewindow'),     thewindow       = 1;        end % seconds
if notDefined('foi'),           foi             = 15;       end % Hz
if nargout < 1, doPlot = true; else doPlot = false;         end

%% Navigate

parentdir = [filesep fullfile('biac3', 'wandell7', 'data', 'ECoG', sprintf('ecog%02.f', subject),'ecog')];

curdir = pwd;
cd(parentdir);

%% Define scans
switch subject
    case 4  
        barscans    = [15, 17, 19, 21];
        onoffscans  = [16, 18, 20];
        mtloc       = [22, 23];  % note that no electrodes covered hMT+ in this patient

        starts.bar   = [-2.5 23.5 8.5 20.4];
        starts.onoff = [16.2468 9.012 14.65];
        starts.mtloc = [0 0 0 0];

        ends.bar    = starts.bar + 96;
        ends.onoff  = starts.onoff + 48;
        ends.mtloc  = [500 500 500 500];

    case 6
        barscans        = [09, 10, 11, 12, 15];
        scissionscans   = 42:45;
        onoffscans      = [13, 14]; %
        
        starts.bar      = [17.7 11.7119 17.5247 11.9355 10.1975];
        starts.onoff    = [10.1 9.2];
        starts.scission = [5.3120   10.6174    4.5888    6.2731];
        
        ends.bar        = starts.bar + 96;
        ends.onoff      = starts.onoff + 48;
        ends.scission   = starts.scission + 96;   
        
    case 8
         barscans        = [36 37 40 41 42];
         onoffscans      = [38 39]; 
%         
%         starts.bar      = [17.7 11.7119 17.5247 11.9355 10.1975];
%         starts.onoff    = [10.1 9.2];
%         
%         ends.bar        = starts.bar + 96;
%         ends.onoff      = starts.onoff + 48;

end

%% Approximate start / end (in s)?
startclip = starts.(scanType)(run); %seconds
endclip   = ends.(scanType)(run);   %seconds

%% Find the dir and run
switch scanType
    case  'bar'
        thedir = 'Ret_bar';
        therunnum = barscans(run);

    case 'onoff'
        thedir = 'Ret_onoff_fullfield';
        therunnum = onoffscans(run);

    case 'mtloc'
        thedir = 'MTloc';
        therunnum = mtloc(run);

    case 'scission'
        thedir = 'ScissionIllusion';
        therunnum = scissionscans(run);
        
end

switch subject
    case 6
        therun = sprintf('AC0210_%02.0f', therunnum);
        filePrefix  = sprintf('iEEGAC0210_%02.0f_', therunnum); 
    case 4
        therun = ['ST07-' num2str(therunnum)];
        filePrefix  = 'gdat_';
end

%% Load data from specified channels
wave = cell(1, max(theelectrodes));

for ii = theelectrodes;
    switch subject
        case 4
            fname = sprintf('%s%d', filePrefix, ii);
            load(fullfile(thedir, therun, fname));
             wave{ii} = eval(fname);
        case 6
            fname = sprintf('%s%02.0f', filePrefix, ii);
            pth    = fullfile(thedir, therun, fname);
            % sometimes our filenames are forced to be 2 digits and
            % sometimes they are not. try both if needed.
            if ~exist(pth, 'file')
                fname = sprintf('%s%d', filePrefix, ii);
                pth    = fullfile(thedir, therun, fname);
            end
            
            tmp    = load(pth);
            wave{ii} = tmp.wave; clear tmp;
    end
    
end

%% Load analog channel
switch subject
    case 6
        anChan = sprintf('PdioAC0210_%02.0f_02', therunnum);
        load(fullfile(thedir, therun, anChan));
        
        
    case 4
        anChan = 'analog_2';
        load(fullfile(thedir, therun, anChan));
        anlg = eval(anChan);
end

samps = 1:length(anlg);
anSampRate = 24414.1;
samptimes = samps/anSampRate;


%% Plot each data set in amps big 8 x 8 grid
if doPlot,
    figure;
    nplots = ceil(sqrt(length(theelectrodes)));
end

for ii = 1:length(theelectrodes)
    
    thiselectrode = theelectrodes(ii);
    
    if doPlot, subplot(nplots,nplots,ii); end

    % Plot the power for the current electrod
    [s, startTimes, amps, ph] = ecogSTDBins(wave{theelectrodes(ii)}, thewindow, overlap, [], foi, startclip);

    inds = startTimes >= startclip & startTimes < endclip;
    
    % TODO: zero pad the time series if the start time is less than 0
    % (i.e., we are missing some data from the start of the scan)
    
    if doPlot, plot(startTimes(inds), amps(inds));  hold on; end
    
    % Plot the std for the current electrode
    % plot(startTimes(inds), s(inds), 'r'); hold on
    
    % Plot the analog channel
    indsA = samptimes > startclip -1 & samptimes < endclip + 1;
    amp = -anlg*10;
    
    if doPlot,
        plot(samptimes(indsA),amp(indsA),'g');
        axis tight; grid on;
        title(sprintf('Electrode %d; Run %s', thiselectrode, therun))
    end
end

%%  Stuff to return
startTimes  = startTimes(inds)';
amps        = amps(inds,:);
ph          = ph(inds, :);

cd(curdir)