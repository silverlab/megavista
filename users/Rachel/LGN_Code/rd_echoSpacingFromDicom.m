function es = rd_echoSpacingFromDicom(dicomPath, ipat)

% echo spacing = 1/({bandwidth per pixel phase encode}*{number of phase
% encoding samples, first element}) * {ipat factor}

% grappa reduces the number of phase encoding samples

dcminf = dicominfo(dicomPath);

bandwidth = dcminf.Private_0019_1028;
nPESamples = dcminf.Private_0051_100b;

pIdx = strfind(nPESamples,'p');
nPESamples1 = str2double(nPESamples(1:pIdx-1));

es = ipat/(bandwidth*nPESamples1);