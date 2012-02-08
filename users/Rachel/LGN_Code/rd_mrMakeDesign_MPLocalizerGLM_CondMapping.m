% MPLocalizerGLM -- make par files for mrVista

% cd /Volumes/Plata1/LGN/Expt_Files/WC_20110901/MagnoParvo_Localizer_GLM_20110901
% cd /Volumes/Plata1/LGN/Expt_Files/SS_20111007/MagnoParvo_Localizer_GLM_20110901

subjectID = 'SS';
runs = 1:9;
scanDate = '20111007';
mappingName = 'HighLow';

includeResponseCond = 0;
includeColors = 1;

responseCond = 5;

blankCol = [128 128 128]./255; % white
responseCol = [0 0 0]./255; % black

switch mappingName
    case 'MP'
        condMappings = {[1 1]; % MLow -> M
                        [2 1]; % MHigh -> M
                        [3 2]; % PLow -> P
                        [4 2]}; % PHigh -> P

        condNames = {'M','P'};
        
        MCol = [220 20 60]./255; % red
        PCol = [0 0 205]./255; % medium blue
        colors = {blankCol, MCol, PCol, responseCol};
        
    case 'HighLow'
        condMappings = {[1 2]; % MLow -> Low
                        [2 1]; % MHigh -> High
                        [3 2]; % PLow -> Low
                        [4 1]}; % PHigh -> High
        
        condNames = {'High','Low'};
                
        HighCol = [125 38 205]./255; % darker purple
        LowCol = [159 121 238]./255; % lighter purple
        colors = {blankCol, HighCol, LowCol, responseCol};
        
    otherwise
        error('mappingName not recognized')
end

for iRun = 1:length(runs)
    run = runs(iRun);
    load(sprintf('data/mpLocalizerGLM_%s_run%02d_%s', ...
        subjectID, run, scanDate));

    blankCond = find(strcmp(p.Gen.condNames,'blank'));
    stimCondOrder = p.Gen.condOrder;
    stimCondOrder(stimCondOrder==blankCond) = 0; % 0 labels mrVista baseline
    origStimCondOrder = stimCondOrder;
    
    for iMap = 1:length(condMappings)
        condMapping = condMappings{iMap};
        stimCondOrder(origStimCondOrder==condMapping(1)) = condMapping(2);
    end
    
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
    
    names = {'blank', condNames{:}, 'response'};
    for iEvent = 1:nEvents
        eventNames{iEvent,1} = names{events(iEvent,2)+1};
        eventColors{iEvent,1} = colors{events(iEvent,2)+1};
    end
    
    % write text file
    fileName = sprintf('%s_%s_%s_run%02d.par', subjectID, scanDate, mappingName, run);
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



