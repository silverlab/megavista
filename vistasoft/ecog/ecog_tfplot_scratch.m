

% cd('/Volumes/Tweedledee/ECoG');

% ecogpath
samplerate = 3051.76;
analog_samprate = 24414.1;

% thePath.block = fullfile(thePath.data, 'ST03_bl18'); % ITEM

% blockpath = '/biac3/wandell7/data/ECoG/ecog02/ecog/AIN/ST03_bl18';
% behpath = '/biac3/wandell7/data/ECoG/ecog02/ecog/AIN/behavioral';
% addpath(behpath);
% tfile = 'ain.2.out.txt';
% condtype = 'ITEM';

% blockpath = '/biac3/wandell7/data/ECoG/ecog02/ecog/miniKM/ST03_bl19'; % ECoG data dir
% behpath = '/biac3/wandell7/data/ECoG/ecog02/ecog/miniKM/behavioral'; % Behavioral data dir (where event files are)
% addpath(behpath);
% tfile = 'cond14.obj1.db1.txt';

%blockpath = '/biac3/wandell7/data/ECoG/ecog04/ecog/MTloc/ST07-22'; % ECoG data dir
blockpath = '/biac3/wandell7/data/ECoG/ecog03/ecog/MTloc/st06_30';
behpath = '/biac3/wandell7/data/ECoG/ecog03/ecog/MTloc/behavioral'; % Behavioral data dir (where event files are)
addpath(behpath);
tfile = 'MTloc_eventFile_bl22.txt';


analogChan = 'analog_2';  % photodiode channel is different for every patient, specify here

cd(blockpath);
load([analogChan '.mat']); 

firstIndex = 15;  % note firstIndex is about 250 for bl26 in ecog03 because of lots of noise in photodiode channel in beginning
[onsets firstEvent] = getAnalogOnsets(eval(analogChan),analog_samprate,firstIndex);

% convert firstEvent to units of EEG samples (i.e. samplerate) from analog samples
firstEvent = (firstEvent/analog_samprate)*samplerate;

[truestamps conds] = assignOnsets(tfile,onsets);

% Here the EEG struct is saved as a .set file that can be read by EEGlab.
% Load the .set file to view channel data in EEGlab.
chanlist = [57:59];
%resamplerate = 1000;
resamplerate = samplerate;
%resamplerate = 500;
origEEG = chanstruct(truestamps,firstEvent,conds,blockpath,chanlist,samplerate,resamplerate,'MTloc_ecog03_bl26');

% Subsequent epoching and baseline commands can be performed without using
% the EEGlab GUI...
% These steps should be performed separately for each condition, then do
% the epoch averaging in Matlab

prestimdur = 0.2; %0.1; % 0.1 seconds
epochmax = 5; %4; %5.0;  % 3 seconds

%% AIN task

% Condition 1: Hits
EEG = pop_epoch( origEEG, {'1'}, [-1*prestimdur epochmax], 'newname', '4chan epochs', 'epochinfo', 'yes'); % HITS
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
hitsMat = EEG.data;
        
% Condition 2: CRs
EEG = pop_epoch( origEEG, {'2'}, [-1*prestimdur epochmax], 'newname', '4chan epochs','epochinfo', 'yes'); % CR
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
crMat = EEG.data;

% here we will have to gather data from all relevant blocks before
% averaging

hitsMat = mean(hitsMat,3);
crMat = mean(crMat,3);
figure(99);
%% end AIN task


%% MT localizer
% Condition 1: Static
EEG = pop_epoch( origEEG, {'1'}, [-1*prestimdur epochmax], 'newname', '4chan epochs', 'epochinfo', 'yes'); % HITS
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
staticMat = EEG.data;    
% Condition 2: Motion
EEG = pop_epoch( origEEG, {'2'}, [-1*prestimdur epochmax], 'newname', '4chan epochs','epochinfo', 'yes'); % CR
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
motionMat = EEG.data;
% average and plot
staticMat = mean(staticMat,3);
motionMat = mean(motionMat,3);
%% end MT localizer


% EEG.pnts/EEG.srate = time in seconds

% chan x timepoints x epochs


% Plotting
colsinPlot = 4;
rowsinPlot = ceil(EEG.nbchan/colsinPlot);
figure;
for chanNum = 1:EEG.nbchan
    subplot(rowsinPlot,colsinPlot,chanNum)
    %plotchan(chanNum,staticMat,motionMat);
    plotchan(chanNum,motionMat)  % only plot MotionMat
end


% % To plot trials events over one channel's data, for a quick look:
sampStamps=(truestamps*samplerate)+firstEvent; % truestamps in samples
chan = load('gdat_58.mat');
figure
plot(chan.gdat_58);
hold on
plot(firstEvent,(5*10^-4),'m*')
plot(sampStamps,4*10^-4,'g*')


%% Code for Berkeley's time-frequency plotsysm,
% EEGdata = one ECOG electrode data.
% events = vector with ones at the location of the event and zeros elsewhere (the length should be the same as the EEGdata)
% srate = sampling rate
% freqH = list of the upper bound of the frequency bands you want to generate the spectogram for
% e.g. [1 5 7 15 20 30 45 55 70 100 140 190]
% freqL = list of the lower bound of the frequency bands you want to generate the spectogram for
% [3 8 13 25 35 50 60 80 120 160 230 260]
% Tbefore is the time in seconds before the event you want to generate the spectogram for
% Tafter is the time in seconds after the event you want to generate the
% spectogram for

% Get timestamps specific to condition
sampStamps=(truestamps*samplerate)+firstEvent; % truestamps in samples
badInds = find(truestamps<0);
cond1Inds = find(conds==1);  % get conds from assignOnsets
cond1Inds = setdiff(cond1Inds,badInds);
cond2Inds = find(conds==2);
cond2Inds = setdiff(cond2Inds,badInds);
cond1Stamps = sampStamps(cond1Inds);
cond2Stamps = sampStamps(cond2Inds);

% Load channel and event data
chan = load('gdat_57.mat');

% condition 1
events1 = zeros(1,length(chan.gdat_57));
events1(round(cond1Stamps))=1;

% condition 2 events
events2 = zeros(1,length(chan.gdat_57));
events2(round(cond2Stamps))=1;

% Resample events
event1times = find(events1)/samplerate;
event2times = find(events2)/samplerate;
event1resamps = event1times * resamplerate;
event2resamps = event2times * resamplerate;
events1_resamp = zeros(1,length(origEEG.data));
events1_resamp(round(event1resamps))=1;
events2_resamp = zeros(1,length(origEEG.data));
events2_resamp(round(event2resamps))=1;

% If you want, cut off first and last event
tmpInd = find(events2_resamp);
events2_resamp(tmpInd(1))=0;
events2_resamp(tmpInd(end))=0;
tmpInd = find(events1_resamp);
events1_resamp(tmpInd(1))=0;
events1_resamp(tmpInd(end))=0;


%events(round(sampStamps)) = 1; % Why was one of the stamps slightly off???? at a pause point
% 
freqH=[3 8 13 25 35 50 60 80 120 160 230 260]; % these reversed in email instructions?
freqL= [1 5 7 15 20 30 45 55 70 100 140 190];

% freqH=[10 30 58 100 150];
% freqL= [1 11 31 62 101];

Tbefore = 0.5;
Tafter = 4;

chanNum = 2;  % corresponds to entry in origEEG, which may not be the same as the actual channel number
outputmat=XCR_spect(origEEG.data(chanNum,:),events2,samplerate,freqH,freqL,Tbefore,Tafter);
%outputmat=XCR_spect(EEGdata,eventdata,srate,freqH,freqL,Tbefore,Tafter);

% Plot the power spectra
% This code will plot a separate power trace for each frequency band.
figure
nBands = length(freqL);
for curBand=nBands:-1:1  % specified by freqL and freqH
    x = -Tbefore : 0.01 : Tafter;
    samps = 1:length(outputmat(1,:));
    samptimes = (samps/samplerate)-Tbefore;
    subplot(nBands,1,nBands+1-curBand)
    plot(samptimes,outputmat(curBand,:))
    set(gca,'xtick',[])  % suppress ticks
end
% Reset the bottom subplot to have xticks
set(gca,'xtickMode', 'auto')
xlabel('Time (secs)')
ylabel('Change in power (z-score?)')


% Another way of plotting with pretty colors
% Output mat is a bunch of z-scores in each frequency band at each sample.
% This will plot samples x freq band (all of outputmat) for a single
% electrode.  It will only plot values above (or below) z_cut.
figure
mn = -10;
mx = 10;
z_cut = 3;
numChans = size(origEEG.data,1);
nBands = length(freqL);
ncols = 4;
nrows = ceil(numChans/ncols);
sr = resamplerate;
for chanNum = 1:numChans
    outputmat=XCR_spect(origEEG.data(chanNum,:),events2_resamp,sr,freqH,freqL,Tbefore,Tafter);
    %outputmat2=outputmat;
    %outputmat1=XCR_spect(origEEG.data(chanNum,:),events1_resamp,sr,freqH,freqL,Tbefore,Tafter);
    %diffoutputmat = outputmat2-outputmat1;
    to_plot = double(outputmat.*(outputmat>z_cut | outputmat<-z_cut));  % just plot one of the outputmats
    %to_plot = double(diffoutputmat.*(diffoutputmat>z_cut | diffoutputmat<-z_cut));  % difference (am i allowed to do this???)
    h = subplot(ncols,nrows,chanNum);
    xscale = -Tbefore*sr:Tafter*sr;  % sometimes there is a sample missing, so add 1 (not sure why???)
    try   %hack to
        pcolor(xscale,1:nBands,double(to_plot));
    catch
        disp('Adjusting xscale')
        xscale=-Tbefore*sr:Tafter*sr+1;
        pcolor(xscale,1:nBands,double(to_plot));
    end
    %pcolor(-Tbefore*samplerate:Tafter*samplerate,1:nBands,double(outputmat)); % no z-cutoff
    %pcolor(double(outputmat))
    shading interp; caxis([mn mx]);
    title(['Chan ' num2str(chanNum)])
    % need to relabel axes here (to seconds on x axis and correct freq bands on
    % y axis)-- or, resample outputmat to milliseconds to start with

end





% Next: select specific events from tfile to plot (rather than all events)
% figure out mapping for electrodes to exclude (patient ME)
% Rereference