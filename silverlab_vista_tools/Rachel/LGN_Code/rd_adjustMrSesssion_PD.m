% rd_adjustMrSession_PD.m

load mrSESSION

mrSESSION.inplanes.fullSize = [256 256];
mrSESSION.inplanes.voxelSize = [0.7500 0.7500 2.0000];
mrSESSION.inplanes.nSlices = 59;
mrSESSION.inplanes.crop = [1 1; 256 256];
mrSESSION.inplanes.cropSize = [256 256];