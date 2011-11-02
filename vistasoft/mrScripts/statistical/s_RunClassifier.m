%% s_RunClassifier
%
% Illustrates how to initialize the gray and volume views
%
% You might set up a path file that includes vistadata on your path, and
% you might call it vistaDataPath
%
% Stanford VISTA

%% Initialize the key variables and data path:
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');
roiName = 'LV1';
measure = 'tscores';

%% Get structure containing svm data:
svm = svmInit('path', dataDir, 'roi', roiName, 'measure', measure);

%% Run SVM, printing summary to terminal returning models structure:
models = svmRun(svm);

%% Export a parameter map with weights from classifier:
saveToView = 'inplane';
svmExportMap(svm, models, [2 3], 'savetoview', saveToView);