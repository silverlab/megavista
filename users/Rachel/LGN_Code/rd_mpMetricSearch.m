% rd_mpMetricSearch.m
% 
% search on linear combination of 6 terms:
% - vals (eg. z-scores, beta vals) from the 4 stimulus conditions
% - abs(high-low contrast vals) for M and P

%% Setup
hemi = 1;
scanDate = '20110920';
analysisDate = '20110920';

trainingProp = .8;
startingCoefs = [1 1 1 1 1 1]; % does not get used if randomly iterating
nIter = 10000;
coefRange = 20;

% use just one of these at a time
mpThresh = 0; % M/P classification threshold
mpProp = .3; % proportion of M voxels

plotFigs = 1;
saveAnalysis = 0;

%% File I/O
fileBase = sprintf('lgnROI%dAnalysis_%s', hemi, scanDate);
analysisExtension = sprintf('_mpDistributionZ%s', analysisDate);
loadpath = sprintf('%s%s.mat', fileBase, analysisExtension);

%% Load data
load(loadpath)

%% Set data, coords, coefs
coords = data(1).lgnROICoords';
data = zScores; % overwrites preexsting 'data' variable
dataNames = condNames;

nVox = size(data,1);
nConds = size(data,2);
nCoefs = numel(startingCoefs);

%% Determine training and testing voxels
nTrainingVox = round(nVox*trainingProp);
shuffledVox = randperm(nVox);
trainingVox = sort(shuffledVox(1:nTrainingVox));
testingVox = sort(shuffledVox(nTrainingVox+1:end));

%% Arrange vals
vals = zeros(nVox, nCoefs);
vals(:,1:nConds) = data;
vals(:,nConds+1) = abs(data(:,strcmp(dataNames,'MHigh')) - data(:,strcmp(dataNames,'MLow')));
vals(:,nConds+2) = abs(data(:,strcmp(dataNames,'PHigh')) - data(:,strcmp(dataNames,'PLow')));

%% Coef names
coefNames = condNames;
coefNames{5} = 'abs(MHigh-MLow)';
coefNames{6} = 'abs(PHigh-PLow)';

%% Separate vals and coords into training set and test set
valsTrain = vals(trainingVox,:);
valsTest = vals(testingVox,:);

coordsTrain = coords(trainingVox,:);
coordsTest = coords(testingVox,:);

%% Optimization on coefs using training vals
optOptions = optimset;
% optOptions.Display = 'iter';

for iIter = 1:nIter
    
    if rem(iIter,100)==0
        fprintf('%d\n', iIter)
    end
    
    c0 = (rand(1,6)-0.5)*coefRange;
    
    [c fval exitflag output] = fminsearch(@(c) ...
        rd_calculateCost2(c, valsTrain, coordsTrain, mpProp), ...
        c0, ...
        optOptions);
    
    startingCoefs(iIter,:) = c0;
    coefs(iIter,:) = c;
    costVal(iIter,:) = fval;
    
end

figure
plot(costVal)

%% Make voxel selectors for plotting
voxSelector = zeros(1, size(vals,1));
trainingVoxSelector = voxSelector;
testingVoxSelector = voxSelector;
trainingVoxSelector(trainingVox) = 1;
testingVoxSelector(testingVox) = 1;
trainingVoxSelector = logical(trainingVoxSelector);
testingVoxSelector = logical(testingVoxSelector);

%% Save results
save('mpMetricSearch0002.mat',...
    'coefs', 'costVal', 'trainingVox', 'testingVox', ...
    'vals', 'valsTrain', 'valsTest', 'coordsTrain', 'coordsTest', ...
    'mpThresh', 'coefNames', 'trainingVoxSelector', 'testingVoxSelector') 

%% Examine coefs
goodCostThresh = -.8;
goodRuns = find(costVal<goodCostThresh);
goodCoefs = coefs(goodRuns,:); 
coefNow = goodCoefs(11,:)

bestRun = find(costVal==min(costVal));
bestCoefs = coefs(bestRun,:); 
coefNow = bestCoefs(1,:);

for iRun = 1:size(bestCoefs,1)
    bestCostTest(iRun,:) = rd_calculateCost(bestCoefs(iRun,:), ...
        valsTest, coordsTest, mpThresh);
end

for iRun = 1:size(goodCoefs,1)
    goodMetricTrain(:,iRun) = valsTrain*goodCoefs(iRun,:)';
    goodMetricTest(:,iRun) = valsTest*goodCoefs(iRun,:)';
end

for iRun = 1:size(bestCoefs,1)
    bestMetricTrain(:,iRun) = valsTrain*bestCoefs(iRun,:)';
    bestMetricTest(:,iRun) = valsTest*bestCoefs(iRun,:)';
end

figure
plot(goodMetricTrain)
figure
plot(goodMetricTest)

figure
plot(bestMetricTrain)
figure
plot(bestMetricTest)

figure
for iCoef = 1:nCoefs
    subplot(nCoefs,1,iCoef)
    hist(goodCoefs(:,iCoef))
    xlim([-coefRange/2 coefRange/2])
    title(sprintf('coef %d', iCoef))
end

figure
coefsToPlot = [3 5 6];
scatter3(goodCoefs(:,3),goodCoefs(:,5),goodCoefs(:,6),50,costVal(goodRuns),'.')
xlabel(sprintf('coef %s', coefNames{coefsToPlot(1)}))
ylabel(sprintf('coef %s', coefNames{coefsToPlot(2)}))
zlabel(sprintf('coef %s', coefNames{coefsToPlot(3)}))

figure
scatter(goodCoefs(:,5),goodCoefs(:,6),50,costVal(goodRuns),'.')









