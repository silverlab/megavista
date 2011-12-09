%% compute the expected coherence of a single spike train and estimated PSTH
function cStruct = compute_coherence_bound(psthHalf1, psthHalf2, numSpikeTrials, sampleRate, freqCutoff, windowSize)

    %% compute coherence between two halves of PSTH
    cMeanHalves = compute_coherence_mean(psthHalf1, psthHalf2, sampleRate, freqCutoff, windowSize);
    
    %% compute normalized (single spike) expected coherences (Eq. 8 of Hsu
    %% et al), these are upper bounds that a perfect model can achieve
    cStruct = struct;
    cStruct.f = cMeanHalves.f;
    cStruct.c = cMeanHalves.c;
    index = find(cMeanHalves.c > 0);
    kdown = (-numSpikeTrials + numSpikeTrials*sqrt(1 ./ cMeanHalves.c(index))) / 2;
    cStruct.c(index) = 1 ./ (kdown + 1);
    
    cStruct.cUpper = cMeanHalves.cUpper;
    index = find(cMeanHalves.cUpper > 0);
    kdown = (-numSpikeTrials + numSpikeTrials*sqrt(1 ./ cMeanHalves.cUpper(index))) / 2;
    cStruct.cUpper(index) = 1 ./ (kdown + 1);
    
    cStruct.cLower = cMeanHalves.cLower;
    index = find(cMeanHalves.cLower > 0);
    kdown = (-numSpikeTrials + numSpikeTrials*sqrt(1 ./ cMeanHalves.cLower(index))) / 2;
    cStruct.cLower(index) = 1 ./ (kdown + 1);
    
    %% compute info values
    df = cStruct.f(2) - cStruct.f(1);
    cStruct.info = -df*sum(log2(1 - cStruct.c));
    cStruct.infoUpper = -df*sum(log2(1 - cStruct.cUpper));
    cStruct.infoLower = -df*sum(log2(1 - cStruct.cLower));
    