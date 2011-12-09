% HemifieldMapping -- make multiple conditions cell array for spm

nScans = 2;
blockDuration = 6; % in scans
nBlocks = 22;

onsetTimes = 0:blockDuration:blockDuration*nBlocks*nScans;
condOrder = repmat([2 1],1,nBlocks/2*nScans); % 1=left, 2=right - left is presented first, but first half-cycle is discarded
names = {'left','right'}; 

for iCond = 1:length(names)
    onsets{iCond} = onsetTimes(condOrder==iCond);
    durations{iCond} = blockDuration;
end

save design.mat names onsets durations