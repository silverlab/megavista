% once your mrVista session is open and set to the correct data type, make
% the model call:

outFileName = sprintf('average-Baseline-Removed-Detrend-MinusOneHalf%s', date);
prfModels = {'one gaussian'};
vw = getSelectedInplane;
searchType  = 'coarse to fine';




% run it
INPLANE{1} = rmMain(vw,[],searchType,'matFileName',outFileName, ...
    'calcPC', false, 'coarseToFine', false, 'model',prfModels, 'datadrivendc', true);

%% ***********************
% parameter check
% ***********************

% ECOG 6
params = viewGet(vw, 'rmStimParams');
disp(params)
% 
%            stimType: 'StimFromScan'
%            stimSize: 9.800000000000001
%           stimWidth: 90
%           stimStart: 0
%             stimDir: 0
%             nCycles: 1
%          nStimOnOff: 4
%          nUniqueRep: 1
%     prescanDuration: 0
%                nDCT: -0.500000000000000
%             hrfType: 'impulse'
%           hrfParams: {[1.680000000000000 3 2.050000000000000]  [1x5 double]}
%         framePeriod: 1
%             nFrames: 96
%          fliprotate: [0 0 0]
%              imFile: '/biac3/wandell7/data/ECoG/ecog06/ecog/eCOGpRF/Stimuli/8barsECOG-images.mat'
%          jitterFile: '/biac3/wandell7/data/ECoG/ecog06/ecog/eCOGpRF/Stimuli/None'
%          paramsFile: '/biac3/wandell7/data/ECoG/ecog06/ecog/eCOGpRF/Stimuli/8barsEcog-params.mat'
%            imFilter: 'binary'
%              images: [7989x96 single]
%          stimwindow: [10201x1 logical]
%        instimwindow: [7989x1 double]
%          images_org: [7989x96 single]


% ECOG 4
params = viewGet(vw, 'rmStimParams');
disp(params)
% params = 
% 
%            stimType: '8Bars'
%            stimSize: 16.500000000000000
%           stimWidth: 90
%           stimStart: 0
%             stimDir: 0
%             nCycles: 1
%          nStimOnOff: 4
%          nUniqueRep: 1
%     prescanDuration: 0
%                nDCT: -0.500000000000000
%             hrfType: 'impulse'
%           hrfParams: {[1.680000000000000 3 2.050000000000000]  [1x5 double]}
%         framePeriod: 1
%             nFrames: 96
%          fliprotate: [0 0 0]
%              imFile: '/biac3/wandell7/data/ECoG/ecog04/ecog/eCOGpRF/eCOGpRF/Stimuli/None'
%          jitterFile: '/biac3/wandell7/data/ECoG/ecog04/ecog/eCOGpRF/eCOGpRF/Stimuli/None'
%          paramsFile: '/biac3/wandell7/data/ECoG/ecog04/ecog/eCOGpRF/eCOGpRF/Stimuli/None'
%            imFilter: 'None'
%              images: [7825x96 double]
%          stimwindow: [10201x1 logical]
%        instimwindow: [7825x1 double]
%          images_org: [7825x96 double]