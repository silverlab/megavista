function [oddPsths, evenPsths] = compute_psth_halves(srData)

    pairCount = length(srData.datasets);
    oddPsths = cell(pairCount, 1);
    evenPsths = cell(pairCount, 1);
    
    for k = 1:pairCount
       
        ds = srData.datasets{k};
        stimLength = ds.stim.stimLength;
        
        slen = length(ds.resp.rawSpikeTimes);
        oddSpikeNum = floor(slen / 2) + mod(slen, 2);
        evenSpikeNum = floor(slen / 2);
        
        oddSpikeTimes = cell(oddSpikeNum, 1);
        evenSpikeTimes = cell(evenSpikeNum, 1);
        for j = 1:slen
            indx = round(floor(j/2)) + mod(j, 2);
            if mod(j, 2) == 0
               oddSpikeTimes{indx} = ds.resp.rawSpikeTimes{j};
            else
               evenSpikeTimes{indx} = ds.resp.rawSpikeTimes{j}; 
            end
        end
        
        oddPsths{k} = make_psth(oddSpikeTimes, stimLength*1e3, 1);
        evenPsths{k} = make_psth(evenSpikeTimes, stimLength*1e3, 1);
        
    end
    