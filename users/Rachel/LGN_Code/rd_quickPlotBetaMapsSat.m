% rd_quickPlotBetaMapsSat.m

hemis = [1];

% Full ops:
% voxSelectOptions = {'all', 'varExp'};
% saturationOptions = {'full', 'varExp'};
% betaSettings = {[.5 -.5], 'betaM-P'; ...
%                 [1 0], 'betaM'; ...
%                 [0 1], 'betaP'};
% varThreshs = [.005 .01 .02 .05];

% Selected ops:
voxSelectOptions = {'all', 'varExp'};
saturationOptions = {'full'};
betaSettings = {[.5 -.5], 'betaM-P'; ...
                [1 0], 'betaM'; ...
                [0 1], 'betaP'};
varThreshs = [.005 .01];

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