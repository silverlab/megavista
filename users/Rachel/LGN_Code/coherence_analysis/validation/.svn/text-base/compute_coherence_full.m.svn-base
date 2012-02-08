function [cModelBound, cSingleSpike] = compute_coherence_full(modelResponse, psth, psthHalf1, psthHalf2, sampleRate, numTrials, freqCutoff, windowSize)

    if nargin < 7
        freqCutoff = -1;
    end
    if nargin < 8
        windowSize = 0.500;
    end

    %% compute coherence between model response and mean PSTH
    cMean = compute_coherence_mean(modelResponse, psth, sampleRate, freqCutoff, windowSize);
    
    %% compute coherence between two halves of PSTH
    cMeanHalves = compute_coherence_mean(psthHalf1, psthHalf2, sampleRate, freqCutoff, windowSize);
    
    %% compute normalized (single spike) expected coherences (Eq. 8 of Hsu
    %% et al), these are upper bounds that a perfect model can achieve
    cModelBound = struct;
    cModelBound.f = cMeanHalves.f;
    cModelBound.c = cMeanHalves.c;
    index = find(cMeanHalves.c ~= 0);
    kdown = (-numTrials + numTrials*sqrt(1 ./ cMeanHalves.c(index))) / 2;
    cModelBound.c(index) = 1 ./ (kdown + 1);
    
    cModelBound.cUpper = cMeanHalves.cUpper;
    index = find(cMeanHalves.cUpper ~= 0);
    kdown = (-numTrials + numTrials*sqrt(1 ./ cMeanHalves.cUpper(index))) / 2;
    cModelBound.cUpper(index) = 1 ./ (kdown + 1);
    
    cModelBound.cLower = cMeanHalves.cLower;
    index = find(cMeanHalves.cLower ~= 0);
    kdown = (-numTrials + numTrials*sqrt(1 ./ cMeanHalves.cLower(index))) / 2;
    cModelBound.cLower(index) = 1 ./ (kdown + 1);

    %% compute coherences between a single trial and the model response,
    %% corresponds to Eq 11 in Hsu et al and respresents how good the model is
    cSingleSpike = struct;
    
    cSingleSpike.f = cMean.f;
    cSingleSpike.c = cMean.c;
    index = find(cMean.c ~= 0);
    chval = cMeanHalves.c(index);
    rhs = (1 + sqrt(1 ./ chval)) ./ (-numTrials + numTrials*sqrt(1 ./ chval)+2); %rhs of Eq 11 in Hsu et. al
    cSingleSpike.c(index) = cMean.c(index) .* rhs;
    
    cSingleSpike.cUpper = cMean.cUpper;
    index = find(cMean.cUpper ~= 0);
    chval = cMeanHalves.cUpper(index);
    rhs = (1 + sqrt(1 ./ chval)) ./ (-numTrials + numTrials*sqrt(1 ./ chval)+2); %rhs of Eq 11 in Hsu et. al
    cSingleSpike.cUpper(index) = cMean.cUpper(index) .* rhs;
    
    cSingleSpike.cLower = cMean.cLower;
    index = find(cMean.cLower ~= 0);
    chval = cMeanHalves.cLower(index);
    rhs = (1 + sqrt(1 ./ chval)) ./ (-numTrials + numTrials*sqrt(1 ./ chval)+2); %rhs of Eq 11 in Hsu et. al
    cSingleSpike.cLower(index) = cMean.cLower(index) .* rhs;
    
    clear chval;
    clear rhs;
    clear cMean;
    clear cMeanHalves;
    
    %% compute information values
    df = cSingleSpike.f(2) - cSingleSpike.f(1);    
    cSingleSpike.info = -df*sum(log2(1 - cSingleSpike.c));
    cSingleSpike.infoUpper = -df*sum(log2(1 - cSingleSpike.cUpper));
    cSingleSpike.infoLower = -df*sum(log2(1 - cSingleSpike.cLower));
        
    df = cModelBound.f(2) - cModelBound.f(1);    
    cModelBound.info = -df*sum(log2(1 - cModelBound.c));
    cModelBound.infoUpper = -df*sum(log2(1 - cModelBound.cUpper));
    cModelBound.infoLower = -df*sum(log2(1 - cModelBound.cLower));
    