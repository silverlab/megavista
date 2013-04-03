% rd_adjustDataTypesRD20120205_SPMMC.m

load mrSESSION.mat

% correctTR = 2.25; % RD 3T
correctTR = 2; % JN distortion-corrected

nScans = numel(mrSESSION.functionals);

for iScan = 1:nScans
    mrSESSION.functionals(iScan).framePeriod = correctTR;
    dataTYPES(1).scanParams(iScan).framePeriod = correctTR;
end

dataTYPES(3) = [];
dataTYPES(2) = [];

save mrSESSION.mat mrSESSION dataTYPES