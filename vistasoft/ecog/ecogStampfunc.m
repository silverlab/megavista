%% Assign timestamps
function [truestamps,conds,firstEvent] = stampfunc(blockpath,behpath,analogChan,...
    samplerate,analog_samprate,tfile)

load(fullfile(blockpath,[analogChan '.mat']));

firstIndex = 13;
[onsets firstEvent] = ecogGetAnalogOnsets(eval(analogChan),analog_samprate,firstIndex);

% convert firstEvent from analog samples to seconds
firstEvent = firstEvent/analog_samprate;

tfilepath = fullfile(behpath,tfile);
[truestamps conds] = ecogAssignOnsets(tfilepath,onsets);

truestamps = truestamps + firstEvent; % event onsets in seconds, starting at 
% beginning of block recording (not at first trial)

end