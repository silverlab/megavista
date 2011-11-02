
load mrSESSION;

if(isfield(mrSESSION,'mrLoadRetVersion'))
    error(['this mrSESSION is already in mrLoadRet ', num2str(mrSESSION.mrLoadRetVersion),' format!']);
end

if(~isfield(mrSESSION.reconParams(1), 'freqEncodeMatSize'))
    for(ii=1:length(mrSESSION.reconParams))
        mrSESSION.reconParams(ii).freqEncodeMatSize = NaN;
    end
end

if(~isfield(mrSESSION.reconParams(ii), 'inplaneVoxelSize'))
    for(ii=1:length(mrSESSION.reconParams))
        mrSESSION.reconParams(ii).inplaneVoxelSize = NaN;
    end
end

if(~isfield(mrSESSION.reconParams(ii), 'frameRate'))
    for(ii=1:length(mrSESSION.reconParams))
        mrSESSION.reconParams(ii).frameRate = NaN;
    end   
end

save mrSESSION mrSESSION;