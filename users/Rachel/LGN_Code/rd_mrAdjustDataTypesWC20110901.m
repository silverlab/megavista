% rd_adjustDataTypesWC20110901.m

load mrSESSION.mat

correctTR = 2.25;

nScans = numel(mrSESSION.functionals);

for iScan = 1:nScans
    mrSESSION.functionals(iScan).framePeriod = correctTR;
    dataTYPES(1).scanParams(iScan).framePeriod = correctTR;
end

save mrSESSION.mat mrSESSION dataTYPES vANATOMYPATH