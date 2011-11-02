function [behavInfo,newFN] = ecogEventsRemoveFix(fn,saveOutFlag)
%
% Function to read in behavioral file (formatted like a mrVista parfile) from ecog
% experiment and remove the fixation conditions.
%
%  [behavInfo,newFN] = ecogEventsRemoveFix(fn,[saveOutFlag=0])
%
% fn is the filename of the original behavior file
% if saveOutFlag is 1, a new behavior file will be saved out
% behavInfo has 3 fields:  onset (specifies timing), cond (specifies
%   condition number), label (specifies condition label)
%

if notDefined('saveOutFlag')
    saveOutFlag = 0;
end

%% Read in behavior file
fid = fopen(fn);
cols = textscan(fid,'%f%d%s'); %,timestamps,condNums,condLabels);
fclose(fid);

timestamps = cols{1};
condnums = cols{2};
condlabels = cols{3};

%% Find unique conditions in case we want them
for cond = 1:max(condnums)
   i = find(condnums==cond);
   uniqueCondNames{cond} = condlabels{i}; % just in case we want these
end

%% Take out fixations
nonFixInd = find(condnums~=0);  % 0 means fixation
behavInfo.onset = timestamps(nonFixInd);
behavInfo.cond = condnums(nonFixInd);
behavInfo.label = condlabels(nonFixInd);

%% Save out new file if requested
if saveOutFlag
    newFN = [fn(1:end-4) '_noFixation.par'];
    writeParfile(behavInfo,newFN);
else
    newFN = [];
end