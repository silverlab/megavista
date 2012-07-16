% rd_mrMakeMPROIParameterMap.m

%% Setup
varThresh = 0;
prop = .2;
voxelSelectionOption = 'varExp'; % all, varExp
analysisMapName = 'betaM-P';
templateMapName = 'BetaM-P';
saveMapName = 'MPClass';
mapIdx = 2; % the index with the map (in case there are multiple scans in the data type)

saveAnalysis = 1;

threshDescrip = sprintf('%0.03f', varThresh);
voxDescrip = ['varThresh' threshDescrip(3:end)];

%% Set up map
templateMapFile = sprintf('../../Inplane/GLMs/%s.mat', templateMapName);
templateMap = load(templateMapFile);

mapData = zeros(size(templateMap.map{mapIdx}));

%% hemi loop
for hemi = 1:2
    %% File I/O
    fileBase = sprintf('lgnROI%d', hemi);
    analysisExtension = sprintf('comVoxGroupCoords_%s_prop%d_%s', ...
        analysisMapName, round(prop*100), voxDescrip);
    loadFile = dir(sprintf('%s_%s*', fileBase, analysisExtension));
    
    if numel(loadFile)~=1
        error('Too many or too few data files.')
    else
        data = load(loadFile.name);
    end
    

    
    %% Get vox coords and vox groups
    voxCoords = data.voxCoords;
    voxGroups = data.voxGroups;
    nVox = size(voxCoords,1);
    
    %% Code groups as 1 for group 1, -1 for group 2
    voxCodes = (voxGroups==1) + -1*(voxGroups==2);
    
    %% Fill map with codes
    for iVox = 1:nVox
        coords = voxCoords(iVox,:);
        mapData(coords(1),coords(2),coords(3)) = voxCodes(iVox);
    end
end % end hemi loop

%% Save map
map{mapIdx} = mapData;
mapName = saveMapName;
clipMode = [-1 1];

save(sprintf('../../Inplane/GLMs/%s.mat', saveMapName), ...
    'map', 'mapName', 'clipMode')




