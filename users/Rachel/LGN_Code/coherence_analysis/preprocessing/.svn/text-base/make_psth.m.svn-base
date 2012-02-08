function psth = make_psth(spikeTrials, stimdur, binsize)

nbins = round(stimdur/binsize);
psth = zeros(1, nbins);

ntrials = length(spikeTrials);

maxIndx = round(stimdur / binsize);

for k = 1:ntrials
    
    stimes = spikeTrials{k};
    indx = ((stimes > 0) & (stimes < stimdur));
    
    stimes = stimes(indx);
    sindxs = round(stimes/binsize) + 1;
    for j = 1:length(sindxs)
        if sindxs(j) == 0
            sindxs(j) = 1;
        end
        if sindxs(j) > maxIndx
            sindxs(j) = maxIndx;
        end
    end        
        
    psth(sindxs) = psth(sindxs) + 1;    
end

psth = psth / ntrials;
