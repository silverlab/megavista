
clear
cd('/matlab_users/ECoG');
ecogpath
samplerate = 3051.76;
% nchan = 16; % for kohler
% nchan = 84; % for stopsig

for b = 1:5
    switch b
        case 1
            thePath.block = fullfile(thePath.data, 'ST03_bl18'); % ITEM
            tfile = 'ain.2.out.txt';
            condtype = 'ITEM';
        case 2
            thePath.block = fullfile(thePath.data, 'ST03_bl29'); % ITEM
            tfile = 'ain.3.out.txt';
            condtype = 'ITEM';
        case 3
            thePath.block = fullfile(thePath.data, 'ST03_bl30'); % ASSOC
            tfile = 'ain.4.out.txt';
            condtype = 'ASSOC';
        case 4
            thePath.block = fullfile(thePath.data, 'ST03_bl31'); % ASSOC
            tfile = 'ain.5.out.txt';
            condtype = 'ASSOC';
        case 5
            thePath.block = fullfile(thePath.data, 'ST03_bl32'); % ITEM
            tfile = 'ain.6.out.txt';
            condtype = 'ITEM';
            % thePath.block = fullfile(thePath.data, 'ST03_bl65'); % ITEM (monset suspect)
            % tfile = 'ain.7.out.txt';
        case 6
            thePath.block = fullfile(thePath.data, 'ST03_bl66'); % ASSOC
            tfile = 'ain.8.out.txt';
            condtype = 'ASSOC';
        case 7
            thePath.block = fullfile(thePath.data, 'ST03_bl69'); % ASSOC
            tfile = 'ain.9.out.txt';
            condtype = 'ASSOC';
            % thePath.block = fullfile(thePath.data, 'ST03_bl69'); % ITEM (do not use for now)
            % tfile = 'ain.10.out.txt';
    end
    cd(thePath.block);

    % Analog_4 is the trigger channel in this case
    % if strcmp(tfile,'ain.9.out.txt')
    %     load('analog_4a.mat');
    %     analog_4 = analog_4a;
    % elseif strcmp(tfile,'ain.10.out.txt')
    %     load('analog_4b.mat');
    %     analog_4 = analog_4b;
    % else
    %     load('analog_4.mat');
    % end

    % [onsets firstEvent] = getAnalogOnsets(analog_4);
    %
    % tfile = getSSevents(thePath,'StopSig_s1_em.15.06.2008.18.14.mat');
    %
    % [truestamps conds] = assignOnsets(tfile,onsets);
    %
    % save stampinfo.mat;
    %
    %     load stampinfo.mat
    %
    %     clear estruct
    %     n = 1; nn = 1;
    %     while 1
    %         if ~(truestamps(n) == -1) % truestamps==-1 when there is no analog
    %             %                               timestamp for that event, so we don't want
    %             %                               to use it
    %             estruct(nn).type = num2str(conds(n));
    %             estruct(nn).latency = truestamps(n)*samplerate + firstEvent;
    %             estruct(nn).position = 0;
    %             estruct(nn).urevent = [];
    %             nn = nn + 1;
    %         end
    %         n = n + 1;
    %         if n > length(conds)
    %             break
    %         end
    %     end
    %
    for q = 1:4
        startchan = (q-1)*(64/4)+1;
        endchan = startchan +(64/4)-1;
        %     % Concatenate channel data, save as mat file
        %     dat = [];
        %     for n = startchan:endchan
        %         gname = ['gdat_' num2str(n) '.mat'];
        %         try
        %             fprintf(['Reading ' gname '\n']);
        %             load(gname);
        %             eval(['dat = [dat; ' gname(1:end-4) '];']);
        %             eval(['clear ' gname(1:end-4)]);
        %         catch
        %             fprintf(['Could not read ' gname '\n']);
        %             dat = [dat; zeros(1,size(dat,2))];
        %         end
        %     end
        %         savename = ['gdat_' num2str(startchan) 't' num2str(endchan) '.mat'];
        %     eval(['save ' savename ' dat']);
        %     clear gdat*

        %         eval(['load ' savename]);
        eegname = ['eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadset( 'filename', eegname, 'filepath', thePath.block);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = pop_eegfilt( EEG, 0, 100, [], [0]);
        EEG = eeg_checkset( EEG );
        EEG = pop_resample( EEG, 1000);
        filtname = ['filt100_' eegname];
        eval(['save ' filtname ' EEG']);
        
        eegname = ['cr_eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadset( 'filename', eegname, 'filepath', thePath.block);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = pop_eegfilt( EEG, 0, 100, [], [0]);
        EEG = eeg_checkset( EEG );
        EEG = pop_resample( EEG, 1000);
        filtname = ['filt100_' eegname];
        eval(['save ' filtname ' EEG']);

        %         % Import channel data
        %         EEG = pop_importdata( 'dataformat', 'matlab', 'data', [thePath.block '/gdat_all.mat'], 'srate',3051.76, 'pnts',0, 'xmin',0, 'nbchan',84);
        %         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', '16chan');
        %         EEG = eeg_checkset( EEG );
        %
        %         % EEG = pop_importdata( 'dataformat', 'matlab', 'data', fullfile(thePath.block,'analog_4.mat'),'srate',1, 'pnts',0, 'xmin',0, 'nbchan',0);
        %
        %         EEG.event = estruct;
        %         ALLEEG.event = estruct;
        %         EEG = eeg_checkset( EEG );
        %
        %         % events: 1 (hits)
        %         % epoch: [-0.5 3.0] seconds
        %         if strcmp(condtype,'ITEM')
        %             EEG = pop_epoch( EEG, {'1'}, [-0.5 3], 'newname', '16chan epochs', 'epochinfo', 'yes'); % HITS
        % %             EEG = pop_epoch( EEG, {'2'}, [-0.5 3], 'newname', '16chan epochs', 'epochinfo', 'yes'); % CR
        %         elseif strcmp(condtype,'ASSOC')
        %             EEG = pop_epoch( EEG, {'5'}, [-0.5 3], 'newname', '16chan epochs', 'epochinfo', 'yes'); % HITS
        % %             EEG = pop_epoch( EEG, {'6'}, [-0.5 3], 'newname', '16chan epochs', 'epochinfo', 'yes'); % CR
        %         end
        %
        %         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1);
        %         EEG = eeg_checkset( EEG );
        %
        %         % baseline: [-500 0] milliseconds
        %         EEG = pop_rmbase( EEG, [-100 0]);
        %
        %         [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        %         EEG = eeg_checkset( EEG );
        %
        %         eegname = ['eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
        % %         eegname = ['cr_eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
        %         eval(['save ' eegname ' EEG']);

    end
end

% Done:
% Import truestamps and conds into eeglab struct ALLEEG (latency and type)
% -- from eeglab gui, load analog1 (or other data channel) to create the
% ALLEEG struct. then the above code puts the event struct into ALLEEG and
% you can plot the channel data to confirm the event latencies.
% Import all the channels; write a script to do this without the GUI
%
% Next: Check notes. Why is ch53 unloadable? Which channels should be
% loaded? Which channel is the reference? We want to use a common average
% reference.
%
% Channel coordinates will be needed at some point.


% getjitters is probably obsolete

% Is there going to be a problem caused by leaving in EEG data from windows
% where no analog timestamps were recorded? Because then "real" events are
% classified as non-events.