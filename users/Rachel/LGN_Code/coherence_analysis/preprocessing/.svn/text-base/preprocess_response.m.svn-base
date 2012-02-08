function resp = preprocess_response(spikeTrials, stimLength, sampleRate)

    nSpikeTrials = length(spikeTrials);
    spikeIndicies = cell(nSpikeTrials, 1);
    for j = 1:nSpikeTrials
        stimes = spikeTrials{j};
        %turn spike times (ms) into indexes at response sample rate
        stimes = round(stimes*1e-3 * sampleRate);                
        %remove excess zeros
        stimes = stimes(stimes > 0);
        spikeIndicies{j} = stimes;
    end
    psth = make_psth(spikeTrials, stimLength*1e3, 1);
    
    resp = struct;
    resp.type = 'psth';
    resp.sampleRate = sampleRate;
    resp.rawSpikeTimes = spikeTrials;
    resp.rawSpikeIndicies = spikeIndicies;
    resp.psth = psth;
