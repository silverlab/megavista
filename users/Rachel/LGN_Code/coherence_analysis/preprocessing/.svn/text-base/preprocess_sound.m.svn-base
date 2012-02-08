%% Preprocess .wav files and spike times into time-frequency representations and PSTHs
% 
%   Input:
%       rawStimFiles: a cell array of .wav file names
%
%       rawRespFiles: a cell array of spike-time file names. Each file
%         contains a space-separated list of file times, one line for each
%         trial. Each spike time is specified in milliseconds.
%
%       preprocessType: time-frequency representation type, either 'ft',
%         'wavelet', or 'lyons' (defaults to 'ft', see timefreq.m)
%
%       stimParams: parameters for time-frequency representation, or
%         default parameters if not specified or is a struct with no fields
%         (see timefreq.m).
%
%       outputDir: directory to write all preprocessed stim to, defaults to
%         system temp directory.
%
%       stimOutputPattern: a pattern to name preprocessed stimuli output
%         files. Must contain '%d' to match the # of the stimulus, for
%         example 'mystim_%d.mat'. Defaults to 'preprocessed_stim_%d.mat'.
%
%       respOutputPattern: a pattern to name processed response output
%         files, defaults to 'preprocessed_resp_%d.mat'.
%
%   Output:
%       srData:a structure with the following properties:
%
%           .nStimChannels: the # of channels in the stimulus
%
%           .stimAvg: the average time frequency representation across
%               stim/response pairs
%
%           .respAvg: the average PSTH across stim/response pairs and time, a scalar
%
%           .tvRespAvg: the time-averaged PSTH, across stim/response pairs.
%             Each row contians the time-varying response for that stimulus
%             with that particular response held out.
%
%           .stimSampleRate: the preprocessed stimulus sample rate
%
%           .respSampleRate: the preprocessed response sample rate
%
%           .type: the type of preprocessing done ('ft', 'lyons', 'wavelet')
%
%           .datasets: a cell array of structures, each structure with the
%               following properties:
%
%                   .stim.type: 'tfrep'
%                   .stim.rawFile: .wav file that generated tfrep
%                   .stim.rawSampleRate: sample rate of .wav file
%                   .stim.tfrep: the time-frequency representation (see timefreq.m)
%                   .stim.sampleRate: sample rate of spectrogram in Hz
%                   .stim.stimLength: length in seconds of spectrogram
%
%                   .resp.type: 'psth'
%                   .resp.sampleRate: sample rate in Hz of PSTH
%                   .resp.rawSpikeTimes: cell array of spike-time vectors, spike
%                     times in ms
%                   .resp.rawSpikeIndicies: cell array of indexes for each spike
%                     time
%                   .resp.psth: the PSTH generated from spike trials
%
%   Author: Mike Schachter (mike.schachter@gmail.com)
%
function srData = preprocess_sound(rawStimFiles, rawRespFiles, preprocessType, stimParams, outputDir, stimOutputPattern, respOutputPattern)

    if length(rawStimFiles) ~= length(rawRespFiles)
        error('# of stim and response files must be the same!');
    end
    
    if nargin < 3
       preprocessType = 'ft'; 
    end
    if nargin < 4
        stimParams = struct;
    end
    if nargin < 5
       outputDir = tempdir(); 
    end
    if nargin < 6
        stimOutputPattern = 'preprocessed_stim_%d.mat';
    end
    if nargin < 7
        respOutputPattern = 'preprocessed_resp_%d.mat';
    end

    pairCount = length(rawStimFiles);
    srData = struct;
    datasets = cell(pairCount, 1);
    
    %% type checking
    allowedTypes = {'ft', 'wavelet', 'lyons'};    
    if ~ismember(preprocessType, allowedTypes)
        error('Unknown time-frequency representation type: %s\n', preprocessType);
    end
    
    maxStimLen = -1;
    maxRespLen = -1;
    nStimChannels = -1;
    stimSampleRate = 1000;
    respSampleRate = 1000;
    
    %% preprocess each stimulus and response
    for k = 1:pairCount
       
        ds = struct;
       
        %preprocess stimulus        
        stimOutputFname = fullfile(outputDir, sprintf(stimOutputPattern, k));
        fid = fopen(stimOutputFname);
        if fid ~= -1
           fclose(fid);
           %fprintf('Using cached preprocessed stimulus from %s\n', stimOutputFname);
           fvars = load(stimOutputFname);
           ds.stim = fvars.stim;
        else
            wavFileName = rawStimFiles{k};        
            ds.stim.type = 'tfrep';
            ds.stim.rawFile = wavFileName;        
            ds.stim.tfrep = timefreq(wavFileName, preprocessType, stimParams);
            ds.stim.rawSampleRate = ds.stim.tfrep.params.rawSampleRate;
            ds.stim.sampleRate = stimSampleRate;
            ds.stim.stimLength = size(ds.stim.tfrep.spec, 2) / ds.stim.sampleRate;
            stim = ds.stim;
            save(stimOutputFname, 'stim');
        end
        
        %preprocess response
        respOutputFname = fullfile(outputDir, sprintf(respOutputPattern, k));
        fid = fopen(respOutputFname);
        if fid ~= -1
           fclose(fid);
           %fprintf('Using cached preprocessed response from %s\n', respOutputFname);
           fvars = load(respOutputFname);
           ds.resp = fvars.resp;
        else        
            spikeTrials = read_spikes_from_file(rawRespFiles{k});
            resp = preprocess_response(spikeTrials, ds.stim.stimLength, respSampleRate);
            save(respOutputFname, 'resp');
            ds.resp = resp;
        end
        
        %update max sizes
        if nStimChannels == -1
           nStimChannels = size(ds.stim.tfrep.spec, 1);
        end
        if size(ds.stim.tfrep.spec, 2) > maxStimLen
            maxStimLen = size(ds.stim.tfrep.spec, 2);
        end
        if length(ds.resp.psth) > maxRespLen
           maxRespLen = length(ds.resp.psth); 
        end
        
        datasets{k} = ds;
    end
    
   
    %% set dataset-wide values
    srData.stimSampleRate = stimSampleRate;
    srData.respSampleRate = respSampleRate;
    srData.nStimChannels = nStimChannels;
    srData.datasets = datasets;
    
    %% compute averages
    [stimAvg, respAvg, tvRespAvg] = compute_srdata_means(srData);
    srData.stimAvg = stimAvg;
    srData.respAvg = respAvg;
    srData.tvRespAvg = tvRespAvg;
    srData.type = preprocessType;

