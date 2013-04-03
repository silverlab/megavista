function newTrials = rd_adaptationRecodeCond(trials)

% input figData.trials as trials

% setup
nTrialsPerRun = 15;
pairs = [0 1; 2 1; 0 2; 1 2; 1 0; 2 0]';
nPairs = size(pairs,2);
pairCodes = 1:nPairs;
pairLabels = {'blankM','PM','blankP','MP','Mblank','Pblank'};

% separate ends of runs from "real trials"
endOfRun = strcmp(trials.label,'end of run');
realTrialIdxs = find(endOfRun==0);

% get the conds from the block trials -- not the end of run items
condReal = trials.cond(realTrialIdxs);
condRealByRun = reshape(condReal,15,numel(condReal)/nTrialsPerRun);

% first item of each run will be 0 or ''
newCondRealByRun = zeros(size(condRealByRun));
newLabel = [];
newLabel{1} = '';

% get pair code for each pair of trials
for iRun = 1:size(condRealByRun,2)
    for iTrial = 2:size(condRealByRun,1)
        pair = condRealByRun(iTrial-1:iTrial,iRun);
        pairIdx = find(all(pairs == repmat(pair,1,nPairs)));
        newCondRealByRun(iTrial,iRun) = pairCodes(pairIdx);
        newLabel{end+1} = pairLabels{pairIdx};
    end
    newLabel{end+1} = 'end of run';
    newLabel{end+1} = '';
end

newLabel = newLabel(1:end-1);

newCond = zeros(size(trials.cond));
newCond(realTrialIdxs) = newCondRealByRun(:);

% make newTrials. timing info and parfiles stay the same.
newTrials = trials;

newTrials.cond = newCond;
newTrials.label = newLabel;
newTrials.color = [];
newTrials.condNums = pairCodes;
newTrials.condNames = pairLabels;
newTrials.condColors = [];



