function [infoBounds, srData] = compute_coherence_dataset(dataDir, stimFiles, respFiles, makePlot)

    if nargin < 4
        makePlot = 1;
    end
    
    outputDir = fullfile(dataDir, 'output');
    [s,mess,messid] = mkdir(outputDir);
    
    preprocDir = fullfile(dataDir, 'preproc');
    [s,mess,messid] = mkdir(preprocDir);
    
    preprocType = 'ft';
    stimOutPattern = ['stim.preproc-' preprocType '.%d.mat'];
    respOutPattern = ['resp.preproc-' preprocType '.%d.mat'];
    
    srData = preprocess_sound(stimFiles, respFiles, 'ft', struct, preprocDir, stimOutPattern, respOutPattern);
    pairCount = length(srData.datasets);
    
    infoBounds = cell(pairCount, 1);
    
    freqCutoff = 100;
    windowSize = 0.500; %500ms windows for computing FFT segments
    
    %% concatenate PSTH halves across stim/response pairs
    psthHalf1Concat = [];
    psthHalf2Concat = [];
    numSpikeTrials = -1;
    sampleRate = -1;
    for k = 1:pairCount      
      ds = srData.datasets{k};        
      
      if numSpikeTrials == -1
          numSpikeTrials = length(ds.resp.rawSpikeTimes);
      end
      if sampleRate == -1
          sampleRate = ds.resp.sampleRate;
      end
      
      psthdata = split_psth(ds.resp.rawSpikeTimes, ds.stim.stimLength*1e3);
      psthHalf1 = rv(psthdata.psth_half1);
      psthHalf2 = rv(psthdata.psth_half2);      
      psthHalf1Concat = [psthHalf1Concat; psthHalf1];
      psthHalf2Concat = [psthHalf2Concat; psthHalf2];      
    end
    
    %% compute the upper bounds on coherence and information
    cModelBound = compute_coherence_bound(psthHalf1Concat, psthHalf2Concat, numSpikeTrials, sampleRate, freqCutoff, windowSize);
               
    spikeRate = srData.respAvg*srData.respSampleRate;
    
    matFileName = fullfile(outputDir, 'info_bounds.mat');
    save(matFileName, 'infoBounds');
    
    csvFileName = fullfile(outputDir, 'info_vals.csv');
    ivals = [spikeRate, cModelBound.infoLower, cModelBound.info, cModelBound.infoUpper];
    dlmwrite(csvFileName, ivals, ',');
    
    fprintf('Dir: %s\n', dataDir);
    fprintf('\tSpike Rate: %f spikes/s\n', spikeRate);
    fprintf('\tInfo: %f between (%f, %f)\n', cModelBound.info, cModelBound.infoLower, cModelBound.infoUpper);
        
    if makePlot
        figure; hold on;
        plot(cModelBound.f, cModelBound.c, 'k--');
        plot(cModelBound.f, cModelBound.cUpper, 'b-');
        plot(cModelBound.f, cModelBound.cLower, 'r-');
        minF = min(cModelBound.f);
        maxF = max(cModelBound.f);
        axis([minF, maxF, 0, 1]);
    end
