%% Create EEGlab struct
function EEG = createEEG(truestamps,firstEvent,conds,gdatpath,chanlist,samplerate,resamplerate)
%
% EEG = createEEG(gdatpath,estruct,chanlist,samplerate,resamplerate,savename,savepath)
% Produces EEGlab format structure
% No epoching is performed.
% Waveform is resampled if desired.
%

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

% Import channel data
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_importdata( 'dataformat', 'matlab', 'data', gdatpath, 'srate', samplerate, 'pnts',0, 'xmin',0, 'nbchan', length(chanlist));
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

end
