% MPLocalizerGLM -- make par files for mrVista

% cd /Volumes/Plata1/LGN/Expt_Files/WC_20110901/MagnoParvo_Localizer_GLM_20110901
% cd /Volumes/Plata1/LGN/Expt_Files/SS_20111007/MagnoParvo_Localizer_GLM_20110901

subjectID = 'SS';
runs = 1:9;
scanDate = '20111007';

includeResponseCond = 0;
includeColors = 1;

responseCond = 5;

blankCol = [128 128 128]./255; % white
MLowCol = [255	182	193]./255; % pink
MHighCol = [220 20 60]./255; % red
PLowCol = [126	192	238]./255; % light blue
PHighCol = [0 0 205]./255; % medium blue
responseCol = [0 0 0]./255; % black
colors = {blankCol, MLowCol, MHighCol, PLowCol, PHighCol, responseCol};


for iRun = 1:length(runs)
    run = runs(iRun);
    load(sprintf('data/mpLocalizerGLM_%s_run%02d_%s', ...
        subjectID, run, scanDate));
    
    condNames = p.Gen.condNames;
    blankCond = find(strcmp(condNames,'blank'));
    stimCondOrder = p.Gen.condOrder;
    stimCondOrder(stimCondOrder==blankCond) = 0; % 0 labels mrVista baseline
    
    stimDuration = p.Gen.cycleDuration; % in seconds
    blockDuration = (p.Gen.cycleDuration + p.Gen.responseDuration);
    nBlocks = numel(p.Gen.condOrder);

    stimOnsetTimes = 0:blockDuration:blockDuration*nBlocks;
    stimOnsetTimes(end) = [];
    
    stimEvents = [stimOnsetTimes' stimCondOrder'];
    
    responseOnsetTimes = stimOnsetTimes + stimDuration;
    responseCondOrder = ones(size(responseOnsetTimes))*responseCond;
    
    responseEvents = [responseOnsetTimes' responseCondOrder'];
    
    if includeResponseCond
        events = sortrows([stimEvents; responseEvents]);
    else
        events = stimEvents;
    end
    nEvents = size(events,1);
    
    names = {'blank', condNames{1:4}, 'response'};
    for iEvent = 1:nEvents
        eventNames{iEvent,1} = names{events(iEvent,2)+1};
        eventColors{iEvent,1} = colors{events(iEvent,2)+1};
    end
    
    % write text file
    fileName = sprintf('%s_%s_run%02d.par', subjectID, scanDate, run);
    fid = fopen(fileName,'w');
    for iEvent = 1:nEvents
        fprintf(fid, '%3.2f\t%d\t%s', events(iEvent,:), eventNames{iEvent});
        if includeColors
            fprintf(fid, '\t[%.02f %.02f %.02f]\n', ...
                eventColors{iEvent}(1), eventColors{iEvent}(2), eventColors{iEvent}(3));
        else
            fprintf(fid, '\n');
        end
    end
    status = fclose(fid);
    
    % report
    if status==0
        fprintf('Wrote par file %s.\n', fileName)
    else
        fprintf('Check par file %s.\n', fileName)
    end
end



