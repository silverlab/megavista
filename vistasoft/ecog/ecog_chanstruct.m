
function EEG = chanstruct(truestamps,firstEvent,conds,blockpath,chanlist,samplerate,resamplerate,savename,savepath)
%
% EEG = chanstruct(truestamps,firstEvent,conds,blockpath,chanlist,samplerate,resamplerate,savename,<savepath>)
%
% Produces 2 files: 
%  savename.gdat_all.mat - a channels x samples matrix concatenating all channels from gdat_#.mat 
%  savename.set - an EEGlab format structure that can be loaded from the GUI
% Files are saved to savepath.
% No epoching is performed.
% Waveform is resampled if desired.
%

if ~exist('savepath','var')
    savepath = pwd;
end

sampStamps=(truestamps*samplerate)+firstEvent; % truestamps in samples

n = 1; nn = 1;
while 1
    if ~(truestamps(n) == -1) 
        % truestamps==-1 when there is no analog timestamp for that event
        estruct(nn).type = num2str(conds(n));
        estruct(nn).latency = truestamps(n)*samplerate + firstEvent;
        estruct(nn).position = 0;
        estruct(nn).urevent = [];
        nn = nn + 1;
    end
    n = n + 1;
    if n > length(conds)
        break
    end
end

cd(blockpath);
dat = [];
for n = 1:length(chanlist)
    chan = chanlist(n);
    gname = ['gdat_' num2str(chan) '.mat'];
    try
        fprintf(['Reading ' gname '\n']);
        load(gname);
        eval(['dat = [dat; ' gname(1:end-4) '];']);
        eval(['clear ' gname(1:end-4)]);
    catch
        fprintf(['Could not read ' gname '\n']);
        dat = [dat; zeros(1,size(dat,2))];
    end
end
cd(savepath);
gdatname = [savename '.gdat_all.mat'];
eval(['save ' gdatname ' dat']);

% eegname = ['ecogtemp.mat'];
% [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% EEG = pop_loadset( 'filename', eegname, 'filepath', thePath.block);
% [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
% % EEG = pop_eegfilt( EEG, 0, 100, [], [0]);
% % EEG = eeg_checkset( EEG );
% EEG = pop_resample( EEG, 500); 
    
% Import channel data
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_importdata( 'dataformat', 'matlab', 'data', fullfile(savepath,gdatname), 'srate', samplerate, 'pnts',0, 'xmin',0, 'nbchan', length(chanlist));
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'chan');
EEG = eeg_checkset( EEG );

% Add event info for this block
EEG.event = estruct;
ALLEEG.event = estruct;
EEG = eeg_checkset( EEG );

% resample
if samplerate~=resamplerate
    EEG = pop_resample( EEG, resamplerate);
end

% save EEG struct
if ~exist('savename','var')
    savename = 'defaultEEGstruct';
end
% eval(['save ' savename ' EEG']);
EEG = pop_saveset( EEG,  'filename', [savename '.set'], 'filepath', savepath);





