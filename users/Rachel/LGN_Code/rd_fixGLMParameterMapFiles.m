% rd_fixGLMParameterMapFiles

% I was too suspicious of mrVista and made it save a new GLM analysis in
% the wrong way (separate files for residual variance, prop variance
% explained, and separate folders for RawMaps). This puts everything the
% way mrVista will like it.

%% Parameter maps
name = 'Residual Variance';

mappy1 = load(sprintf('Inplane/GLMs/%s1.mat', name))
mappy2 = load(sprintf('Inplane/GLMs/%s2.mat', name))
mapName = mappy1.mapName
map = {mappy1.map{1} mappy2.map{2}}
save(sprintf('Inplane/GLMs/%s.mat',name), mapName, map)

%% RawMaps
files = dir('Inplane/GLMs/RawMaps1');

for iFile = 1:length(files)
    name = files(iFile).name;
    mappy1 = load(sprintf('Inplane/GLMs/RawMaps1/%s', name))
    mappy2 = load(sprintf('Inplane/GLMs/RawMaps2/%s', name))
    mapName = mappy1.mapName
    map = {mappy1.map{1} mappy2.map{2}}
    save(sprintf('Inplane/GLMs/RawMaps/%s',name), 'mapName', 'map')
end
    