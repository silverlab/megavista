% MPLocalizerGLM -- make multiple conditions cell array for spm

% cd /Volumes/Plata1/LGN/Expt_Files/WC_20110901/MagnoParvo_Localizer_GLM_20110901

subjectID = 'WC';
runs = 1 %1:9;
scanDate = '20110901';

TR = 2.25;

condOrder = []; % for all runs
for iRun = 1:length(runs)
    run = runs(iRun);
    load(sprintf('data/mpLocalizerGLM_%s_run%02d_%s', ...
        subjectID, run, scanDate));
    
    condOrder = [condOrder p.Gen.condOrder];
end

stimDuration = p.Gen.cycleDuration/TR;
blockDuration = (p.Gen.cycleDuration + p.Gen.responseDuration)/TR; % in scans
nBlocks = numel(p.Gen.condOrder)*numel(runs);

onsetTimes = 0:blockDuration:blockDuration*nBlocks;

names = p.Gen.condNames;

for iCond = 1:length(names)
    onsets{iCond} = onsetTimes(condOrder==iCond);
    durations{iCond} = stimDuration;
end

save design.mat names onsets durations