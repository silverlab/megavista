%% s_computeContrastMap
%
% Illustrates how to compute a contrast map for later projection onto a 3D
% mesh
%
% You might set up a path file that includes vistadata on your path, and
% you might call it vistaDataPath
%
% Stanford VISTA

%% Initialize the key variables and data path:
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');
dataType = 'MotionComp';

curDir = pwd;
cd(dataDir);

%% Retrieve data structure and set data type:
vw = initHiddenInplane();
vw = viewSet(vw, 'currentDataType', dataType);

%% Get information re: the experiment/trials:
stimuli = er_concatParfiles(vw);
nConds = length(stimuli.condNums);

%% Print condition numbers and names for input into contrast fxn:
fprintf('[##] - Condition Name\n');
fprintf('---------------------\n');
for i = 1:nConds
    fprintf('[%02d] - %s\n', stimuli.condNums(i), stimuli.condNames{i});
end

%% Choose active and control conditions:
activeConds     = [0]; % Fixation
% versus
controlConds    = [1 2]; % Word & WordScramble

% Choose a name for the contrast - left empty to assign default
contrastName    = []; 

%% Compute the contrast map for view on mesh:
computeContrastMap2(vw, activeConds, controlConds, contrastName);

cd(curDir);

%% END

