% rd_mrMakeBetaMPParameterMap.m

% Make a parameter map in the Inplane from betas_predictor1 -
% betas_predictor2.

scanWithMap = 1;

betas1 = load('Inplane/GLMs/RawMaps/betas_predictor1.mat');
betas2 = load('Inplane/GLMs/RawMaps/betas_predictor2.mat');

mapName = 'BetaM-P';
map{scanWithMap} = betas1.map{scanWithMap} - betas2.map{scanWithMap};

save(sprintf('Inplane/GLMs/%s.mat',mapName), 'mapName', 'map')