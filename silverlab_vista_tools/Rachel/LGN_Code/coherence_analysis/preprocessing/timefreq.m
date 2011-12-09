%% General purpose time-frequency representation function
%
%   Input:
%       wavFileName: path to .wav file
%
%       typeName: 'ft' for short-time fourier transforms
%                 'wavelet' for wavelet transforms
%                 'lyons' for lyons-model
%
%       params: depends on typeName, default values used if not given
%
%           'ft' params
%               .fband: spacing between frequency bands of spectrogram (125)
%               .nstd: # of std deviations that define width of Gaussian
%                   window (6)
%               .low_freq: lowest frequency in Hz (250)
%               .high_freq: highest frequency in Hz (8000)
%               .log: take base 10 log of spectrogram (1)
%
%           'wavelet' params
%               (currently not implemented)
%
%           'lyons' params (Requires AuditoryToolbox)               
%               .low_freq: lowest frequency in Hz (250)
%               .high_freq: highest frequency in Hz (8000)
%               .earQ: quality factor of each filter (8)
%               .agc: use adaptive gain control (1)
%               .differ: use differential gain control (1)
%               .tau: time constant of gain control (3)
%               .step: 1/step is approximately the number of filters per bandwidth 
%
%   Output:
%
%       tfrep: time-frequency representation
%           .type: the name of the type of time frequency representation ('ft', 'lyons', 'wavelet')
%           .t: vector of time points for tf-representation
%           .f: vector of frequencies for tf-representation
%           .spec: matrix of values for tf-representation at a given
%               time-frequency cell
%           .params: the parameters that created the time-frequency representation
%
function tfrep = timefreq(wavFileName, typeName, params)

    if nargin < 3
        tfrep = make_tfrep(typeName);
    else
        tfrep = make_tfrep(typeName, params);
    end
    
    %% read .wav file
    [inputData, sampleRate, depth] = wavread(wavFileName);
    tfrep.params.rawSampleRate = sampleRate;
    
    %% create spectrogram
    switch typeName
       
        case 'ft'
            %compute raw complex spectrogram
            twindow = tfrep.params.nstd/(tfrep.params.fband*2.0*pi);   % Window length
            winLength = fix(twindow*sampleRate);  % Window length in number of points
            winLength = fix(winLength/2)*2; % Enforce even window length
            increment = fix(0.001*sampleRate); % Sampling rate of spectrogram in number of points - set at 1 kHz
            
            [s, t0, f0, pg] = GaussianSpectrum(inputData, increment, winLength, sampleRate); 
                       
            %normalize the spectrogram within the specified frequency range
            maxIndx = find(f0 >= tfrep.params.high_freq);
            maxIndx = maxIndx(1);
            minIndx = find(f0 < tfrep.params.low_freq);
            minIndx = minIndx(end) + 1;
            
            normedS = abs(s(minIndx:maxIndx, :));
            normedS = (normedS / max(max(normedS)));
            
            %take log-spectrogram
            if tfrep.params.log
                DBNOISE = 80;
                normedS = max(0, 20*log10(normedS)+DBNOISE);
            end
            
            %set tfrep values
            fstep = f0(2);
            tfrep.t = t0;
            tfrep.f = f0(minIndx):fstep:f0(maxIndx);
            tfrep.spec = normedS;
            
        case 'wavelet'
            fprintf('Wavelets not currently implemented!\n');
            return;
            
        case 'lyons'
            df = sampleRate / 1000; % Decimation factor
            lspec = LyonPassiveEar_new_mod(inputData, sampleRate, df, tfrep.params.low_freq,...
                                           tfrep.params.high_freq, tfrep.params.earQ, tfrep.params.step,...
                                           tfrep.params.differ, tfrep.params.agc, tfrep.params.tau);
            
            tlen = size(lspec, 2);
            flen = size(lspec, 1);
            t0 = (0:(tlen-1))*1e-3;
            finc = round((tfrep.params.high_freq - tfrep.params.low_freq) / flen);
            f0 = tfrep.params.low_freq:finc:tfrep.params.high_freq;
            
            tfrep.spec = flipud(lspec);
            tfrep.t = t0;
            tfrep.f = f0;
    end
    
    