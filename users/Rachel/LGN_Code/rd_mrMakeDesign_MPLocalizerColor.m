% MPLocalizerColor -- make par files for mrVista

% cd /Volumes/Plata1/LGN/Expt_Files/AV_20111117/MagnoParvoLocalizer_Color_20111116/
% cd /Volumes/Plata1/LGN/Expt_Files/AV_20111128/MagnoParvoLocalizer_Color_20111116/
% cd /Volumes/LaCie/fMRI/Expt_Files/KS_20111212/MagnoParvoLocalizer_Color_20111211_7T/
% cd /Volumes/LaCie/fMRI/Expt_Files/AV_20111213/MagnoParvoLocalizer_Color_20111211_7T/
% cd /Volumes/Plata1/LGN/Expt_Files/KS_20111214/MagnoParvoLocalizer_Color_20111211_7T/
% cd /Volumes/Plata1/LGN/Expt_Files/RD_20111214/MagnoParvoLocalizer_Color_20111211_7T/
% cd /Volumes/Plata1/LGN/Expt_Files/CG_20120130/MagnoParvoLocalizer_Color_20111116/
% cd /Volumes/Plata1/LGN/Expt_Files/RD_20120205/MagnoParvoLocalizer_Color_20111116/
% cd /Users/anvu/Documents/DATA/Rachel/MP_Behav/SB_20120807/
% cd /Users/anvu/Documents/DATA/Rachel/MP/Behav/JN_20120808
% cd /Users/anvu/Documents/DATA/Rachel/MP/Behav/RD_20120809
% cd /Volumes/Plata1/LGN/Expt_Files/MN_20120806_MP/MagnoParvo_Localizer/data
cd /Volumes/Plata1/LGN/Expt_Files/CM_20121031/MagnoParvo_Localizer/data

subjectID = 'CM';
runs = 1:8;
scanDate = '20121031';

includeResponseCond = 0;
includeColors = 1;

responseCond = 3;

blankCol = [128 128 128]./255; % gray
MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
responseCol = [0 0 0]./255; % black
colors = {blankCol, MCol, PCol, responseCol};


for iRun = 1:length(runs)
    run = runs(iRun);
%     load(sprintf('data/mpLocalizerGLM_%s_run%02d_%s', ...
%         subjectID, run, scanDate), 'p');
    load(sprintf('mpLocalizerColor_%s_run%02d_GLM_%s', ...
        subjectID, run, scanDate), 'p'); % 7T Aug 2012
    
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
    
    names = {'blank', condNames{1:2}, 'response'};
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



