function [esEff, es] = rd_echoSpacingFromDicom(dicomPath, ipat)

% function es = rd_echoSpacingFromDicom(dicomPath, ipat)
% 
% echo spacing = 1/({bandwidth per pixel phase encode}*{number of phase
% encoding samples, first element}) * {ipat factor}
%
% grappa reduces the number of phase encoding samples
%
% Rachel Denison
% 14 September 2012

dcminf = dicominfo(dicomPath);

bandwidth = dcminf.Private_0019_1028;
nPESamples = dcminf.Private_0051_100b;

pIdx = strfind(nPESamples,'p');
nPESamples1 = str2double(nPESamples(1:pIdx-1));

esEff = 1/(bandwidth*nPESamples1); % as if all the lines were read
es = esEff*ipat; % the actual echo spacing, if only some lines were read (eg. every other line for ipat=2)