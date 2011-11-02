% This script takes importance weight files and length statistic files in
% order to view how parameter changes effect estimates

dir = 'c:\cygwin\home\sherbond\images\aab050307\bin\metrotrac\params_search';

% Setup length penalties that we will calculate
smoothStd = [0.078 0.157 0.314 0.628 0.814 1.26 1.88 2.51];
lengthPenalty = [0.2 0.35 0.42 0.5 0.6 0.75 0.8 0.85 0.90 0.95];
numPaths = 1;

% Get statistic file
lengthStatFilename = fullfile(dir,'statvec1_length.dat');
lengthStat = loadStatvec(lengthStatFilename);

% Setup statistic matrix
S = zeros(length(smoothStd),length(lengthPenalty));

for ss = 1:length(smoothStd)
    for ll = 1:length(lengthPenalty)
        % Get imp_weight file
        smoothName = sprintf('smooth%d',floor(100*smoothStd(ss)));
        lenName = sprintf('len%d',floor(100*lengthPenalty(ll)));
        specificName = sprintf('statvec1_iw_%s_%s',smoothName,lenName);
        iwStatFilename = fullfile(dir,specificName);
        iwStat = loadStatvec(iwStatFilename);
        iwStat = exp(iwStat);
        iwStat(iwStat==0) = realmin;
        S(ss,ll) = sum(iwStat.*lengthStat / sum(iwStat));        
    end
end

bar3(S);