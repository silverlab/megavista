% rd_mrAdjustInplane_MN20120806.m

% also replaced anat.mat with mean of first scan

load mrSESSION.mat

correctInplaneDim = [160 160];
correctRes = [1.3 1.3 1.3]; % MN [1.2 1.2 1.2] % JN, SB, RD [1.3 1.3 1.3]

mrSESSION.inplanes.fullSize = correctInplaneDim;
mrSESSION.inplanes.voxelSize = correctRes;
mrSESSION.inplanes.crop(2,:) = correctInplaneDim;
mrSESSION.inplanes.cropSize = correctInplaneDim;

save mrSESSION.mat mrSESSION dataTYPES