%% Compute the jacknifed multi-tapered coherence and normal mutual information
%% between a model response and mean PSTH. From:
%%
%%  Anne Hsu et al 2004 Network: Comput. Neural Syst. 15 91-109
%
%   Input:
%       modelResponse: time series model response
%
%       psth: time series actual PSTH, should be same length as response
%
%       sampleRate: sample rate of PSTH and model response (should be same)
%
%       freqCutoff: only return info for frequencies less than this (optional)
%  
%       windowSize: length in seconds of segments to take FFT of
%                   and average across
%
%   Output:
%
%       cStruct: structure containing info and coherence values
%
%           .f: frequencies in Hz at which coherence was computed
%           .c: mean coherence at each frequency
%           .cUpper: upper bound of coherence at each frequency (from
%             jacknife)
%           .cLower: lower bound of coherence at each frequency (from
%             jacknife)
%           .info: normal mutual information of mean coherence (see eq. 4
%             of Hsu et. al)
%           .infoUpper: upper bound of normal mutual information
%           .infoLower: lower bound of normal mutual information
%
%   Author:
%
%       Mike Schachter (mike.schachter@gmail.com), ported from
%           SNRInfo_nocutoff.m in STRFPAK.
%
function cStruct = compute_coherence_mean(modelResponse, psth, sampleRate, freqCutoff, windowSize)

    if nargin < 4
        freqCutoff = -1;
    end
    
    if nargin < 5      
      windowSize = 0.500; %default window length of 500ms, 2Hz and up      
    end
    
    %% put psths in matrix for mtchd_JN
    if length(modelResponse) ~= length(psth)
        %fprintf('compute_coherence_mean: Lengths of modelResponse and psth are not the same! Taking the minimum.\n');
        minLen = min(length(modelResponse), length(psth));
        modelResponse = modelResponse(1:minLen);
        psth = psth(1:minLen);
    end
    x = [rv(modelResponse) rv(psth)];
        
    %% compute # of time bins per FFT segment
    minFreq = round(1 / windowSize);
    %fprintf(['Given a window size of %0.3f seconds, the lowest freqency analyzed will be %0.1f Hz\n'], windowSize, minFreq);
    numTimeBin = round(sampleRate*windowSize);
        
    %% get default parameter values
    vargs = {x, numTimeBin, sampleRate};
    [x, nFFT, Fs, WinLength, nOverlap, NW, Detrend, nTapers] = df_mtparam(vargs);
    
    %% compute jacknifed coherence
    [y, fpxy, cxyo, cxyo_u, cxyo_l, stP] = df_mtchd_JN(x, nFFT, Fs, WinLength, nOverlap, NW, Detrend, nTapers);

    %% normalize coherencies
    cStruct = struct;
    cStruct.f = fpxy;
    cStruct.c = cxyo(:, 1, 2).^2;
    cStruct.cUpper = cxyo_u(:, 1, 2).^2;
    
    clo = cxyo_l(:, 1, 2);    
    closgn = sign(real(clo));
    cStruct.cLower = (clo.^2) .* closgn; %cxyo_l can be negative, multiply by sign after squaring
    
    %% restrict frequencies analyzed to the requested cutoff and minimum frequency given the window size
    if freqCutoff ~= -1
        findx = find(cStruct.f < freqCutoff);
        eindx = max(findx);
        indx = 1:eindx;
        
        cStruct.f = cStruct.f(indx);
        cStruct.c = cStruct.c(indx);
        cStruct.cUpper = cStruct.cUpper(indx);
        cStruct.cLower = cStruct.cLower(indx);
    end    
    
    if minFreq > 0        
        findx = find(cStruct.f >= minFreq);
        sindx = min(findx);
        cStruct.f = cStruct.f(sindx:end);
        cStruct.c = cStruct.c(sindx:end);
        cStruct.cUpper = cStruct.cUpper(sindx:end);
        cStruct.cLower = cStruct.cLower(sindx:end);        
    end
       
    
    %% compute information by integrating log of 1 - coherence        
    df = cStruct.f(2) - cStruct.f(1);
    cStruct.minFreq = minFreq;
    cStruct.info = -df*sum(log2(1 - cStruct.c));
    cStruct.infoUpper = -df*sum(log2(1 - cStruct.cUpper));
    cStruct.infoLower = -df*sum(log2(1 - cStruct.cLower));
    