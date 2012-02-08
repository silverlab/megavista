% MPLocalizerGLM -- make multiple conditions cell array for spm

cd /Volumes/Plata1/LGN/Expt_Files/WC_20110901/Hemifield_Burst_20110901/

subjectID = 'WC';
runs = 1:2;
scanDate = '20110901';

TR = 2.25;
trialDuration = 1; % in seconds
stimDuration = 0; % event related
nTRs = 139;
runDur = TR*nTRs;

eventOrder = []; % for all runs
eventTimes = [];
for iRun = 1:length(runs)
    run = runs(iRun);
    load(sprintf('data/hemifieldCheckerboardEvents_%s_run%02d_%s', ...
        subjectID, run, scanDate));
    
    eventOrder = [eventOrder; t.stimEventsOrig(:,2)];
    eventTimes = [eventTimes; t.stimEventsOrig(:,1) + runDur*(iRun-1)];
end

eventOrder(eventOrder==0) = 3;
nTrials = numel(eventOrder);

onsetTimes = eventTimes;

names = {'side1','side2','blank'};

for iEventType = 1:length(names)
    onsets{iEventType} = onsetTimes(eventOrder==iEventType);
    durations{iEventType} = stimDuration;
end

% cd to spm directory
save design.mat names onsets durations