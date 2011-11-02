%% Assign timestamps
function [truestamps,firstEvent,conds] = stampfunc(blockpath,behpath,analogChan,...
    samplerate,analog_samprate,tfile)

load(fullfile(blockpath,[analogChan '.mat']));

firstIndex = 13;
[onsets firstEvent] = getAnalogOnsets(eval(analogChan),analog_samprate,firstIndex);

% convert firstEvent to units of EEG samples (i.e. samplerate) from analog samples
firstEvent = (firstEvent/analog_samprate)*samplerate;

tfilepath = fullfile(behpath,tfile);
[truestamps conds] = assignOnsets(tfilepath,onsets);

end