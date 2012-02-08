% rd_mrMakeMrSESSIONFromSingleScanSESSION.m

load mrSESSION_backup
load mrInit2_params

mrSESSION0 = mrSESSION;

mrSESSION.description = params.description;
mrSESSION.subject = params.subject;

functionals0 = mrSESSION.functionals;

% number of TRs in each scan group
nFrames = [128 135];

% each functional may have a unique PfileName, totalFrames, and nFrames.
% everything else should be the same for a single session.
for iFunc = 1:length(params.functionals)
    
    mrSESSION.functionals(iFunc) = functionals0;
    mrSESSION.functionals(iFunc).PfileName = params.functionals{iFunc};
    
    for iGroup = 1:length(params.scanGroups)
        inGroup(iGroup) = any(iFunc==params.scanGroups{iGroup});
    end
    group(iFunc) = find(inGroup);
    
    mrSESSION.functionals(iFunc).totalFrames = nFrames(group(iFunc));
    mrSESSION.functionals(iFunc).nFrames = nFrames(group(iFunc));
 
end

% Now adjust dataTYPES
scanParams0 = dataTYPES(1).scanParams(1);
dataTYPES = rmfield(dataTYPES,{'blockedAnalysisParams','eventAnalysisParams'});

for iFunc = 1:length(params.functionals)
    
    scanParams = scanParams0;
    scanParams.annotation = params.annotations{iFunc};
    scanParams.nFrames = mrSESSION.functionals(iFunc).nFrames;
    scanParams.PfileName = mrSESSION.functionals(iFunc).PfileName; 
    scanParams.parfile = params.parfile{iFunc};
    groupString = num2str(params.scanGroups{group(iFunc)});
    scanParams.scanGroup = sprintf('%s: %s', dataTYPES(1).name, groupString);
    dataTYPES(1).scanParams(iFunc) = scanParams;
    
    if length(params.coParams)>=iFunc && ~isempty(params.coParams{iFunc})
        dataTYPES(1).blockedAnalysisParams(iFunc) = params.coParams{iFunc};
    else
        dataTYPES(1).blockedAnalysisParams(iFunc) = coParamsDefault;
    end
    if length(params.glmParams)>=iFunc && ~isempty(params.glmParams{iFunc})
        dataTYPES(1).eventAnalysisParams(iFunc) = params.glmParams{iFunc};
    else
        dataTYPES(1).eventAnalysisParams(iFunc) = er_defaultParams;
    end
    
end


