% rd_quickPlotBetaMapsSat.m

hemis = [1 2];

% Some defaults if running rd_plotTopographicData2SatFn directly:
% hemi = 2; voxelSelectionOption = 'all'; saturationOption = 'full';
% betaWeights = [.5 -.5]; name = 'betaM-P'; varThresh = 0; saveFigs = 0;

% Full ops:
% voxSelectOptions = {'all', 'varExp'};
% saturationOptions = {'full', 'varExp'};
% betaSettings = {[.5 -.5], 'betaM-P'; ...
%                 [1 0], 'betaM'; ...
%                 [0 1], 'betaP'};
% varThreshs = [.005 .01 .02 .05];

% Selected ops:
voxSelectOptions = {'all'};
saturationOptions = {'full'};
betaSettings = {[.5 -.5], 'betaM-P'; ...
                [1 0], 'betaM'; ...
                [0 1], 'betaP'};
% betaSettings = {[.5 -.5], 'betaM-P'};
% betaSettings = {[1 0], 'betaM'};
% betaSettings = {[0 1], 'betaP'};

saveFigs = 1;

for iHemi = 1:numel(hemis)
    hemi = hemis(iHemi);
    
    for iVoxSelect = 1:numel(voxSelectOptions)
        voxelSelectionOption = voxSelectOptions{iVoxSelect};
        
        for iSat = 1:numel(saturationOptions)
            saturationOption = saturationOptions{iSat};
            
            for iBeta = 1:size(betaSettings,1)
                betaWeights = betaSettings{iBeta,1};
                betaWeightsName = betaSettings{iBeta,2};
                
                switch voxelSelectionOption
                    case 'all'
                        varThresh = [];
                        
                        rd_plotTopographicData2SatFn(hemi, ...
                            voxelSelectionOption, saturationOption, ...
                            betaWeights, betaWeightsName, varThresh, saveFigs);
                        
                    case 'varExp'
                        for iThresh = 1:numel(varThreshs)
                            varThresh = varThreshs(iThresh);
                            
                            rd_plotTopographicData2SatFn(hemi, ...
                                voxelSelectionOption, saturationOption, ...
                                betaWeights, betaWeightsName, varThresh, saveFigs);
                        end
                        
                    otherwise
                        error('voxelSelection option not found.')
                end
            end
        end
    end
end