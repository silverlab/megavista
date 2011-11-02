% 03/18/09
% Commands to generate TF plot in EEGlab for Item/Assoc data

clear
cd('/Volumes/Tweedledee/ECoG');
ecogpath
samplerate = 3051.76;

thePath.block = fullfile(thePath.data, 'ST03_bl18'); % ITEM
tfile = 'ain.2.out.txt';
condtype = 'ITEM';

cd(thePath.block);

q = 1;
startchan = (q-1)*(64/4)+1;
endchan = startchan +(64/4)-1;

eegname = ['eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset( 'filename', eegname, 'filepath', thePath.block);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

figure; 
chan = 1;
pop_newtimef( EEG, 1, chan, [-500  3000], [3 0.5] ,'type', 'phasecoher', 'title','Channel 2 power and inter-trial phase coherence (16chan epochs)', 'alpha',.01,'padratio', 4, 'plotphase','off');
EEG = eeg_checkset( EEG );