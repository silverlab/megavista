function [stimAvg, respAvg, tvRespAvg] = compute_srdata_means(srData)

    pairCount = length(srData.datasets);

    %% get max response length
    maxRespLen = -1;
    for k = 1:pairCount
        ds = srData.datasets{k};
        if length(ds.resp.psth) > maxRespLen
           maxRespLen = length(ds.resp.psth); 
        end        
    end
    
    %% compute stim and response averages       

    stimSum = zeros(srData.nStimChannels, 1);
    stimCountSum = 0;
    respSum = zeros(1, maxRespLen);
    meanSum = 0;    
    tvRespCount = zeros(pairCount, maxRespLen);
    
    %first compute all the sums
    for k = 1:pairCount
        ds = srData.datasets{k};
        stimSum = stimSum + sum(ds.stim.tfrep.spec, 2);
        stimCountSum = stimCountSum + size(ds.stim.tfrep.spec, 2);
        
        rlen = maxRespLen - length(ds.resp.psth);
        nresp = [ds.resp.psth zeros(1, rlen)];
        respSum = respSum + nresp;
        
        tvIndx = 1:length(ds.resp.psth);
        tvRespCount(k, tvIndx) = 1;
        
        meanSum = meanSum + mean(ds.resp.psth);
    end
    
    %construct the time-varying mean for the response. each row of the
    %tv-mean is the average PSTH (across pairs) computed with the PSTH
    %of that row index left out
    tvRespCountSum = sum(tvRespCount);
    tvRespAvg = zeros(pairCount, maxRespLen);
    smoothWindowTau = 41;
    hwin = hanning(smoothWindowTau);
    hwin = hwin / sum(hwin);  
    halfTau = floor(smoothWindowTau / 2);
    coff = mod(smoothWindowTau, 2);
    for k = 1:pairCount
        ds = srData.datasets{k};
        rlen = maxRespLen - length(ds.resp.psth);
        nresp = [ds.resp.psth zeros(1, rlen)];
        
        %subtract off this pair's PSTH, construct mean
        tvcnts = tvRespCountSum - tvRespCount(k, :);
        tvcnts(tvcnts < 1) = 1;
        tvRespAvg(k, :) = (respSum - nresp) ./ tvcnts;
        
        %smooth with hanning window
        pprod = conv(tvRespAvg(k, :), hwin);
        sindx = halfTau+coff;
        eindx = round(length(pprod)-halfTau);
        tvRespAvg(k, :) = pprod(sindx:eindx);
    end
        
    stimAvg = stimSum / stimCountSum;
    respAvg = meanSum / pairCount;