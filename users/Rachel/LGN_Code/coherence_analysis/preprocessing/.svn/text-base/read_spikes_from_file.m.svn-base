function spikeTrials = read_spikes_from_file(fileName)

    spikeTimes = dlmread(fileName, ' ');
    spikeTrials = cell(size(spikeTimes, 1), 1);
    for j = 1:length(spikeTrials)
        spikeTrials{j} = spikeTimes(j, spikeTimes(j, :) > 0);
    end
    