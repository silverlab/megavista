function []= ecogDataDecomposeBand(par,elecs,locutoff,hicutoff)
% Function: decomposing signal into Ampilitude and Phase for different
% frequencies
% Input: CAR data
% ouput: per channel, amplitude and phase matrix 
% Dependencies; signal processing tooolbox, band_pass.m
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Last revision date SEP,2009
%
% modified by amr Feb 18, 2011 to fit into mrVista structure, and allow
% passing in band values
%
%  []= ecogDataDecomposeBand(par,elecs,locutoff,hicutoff)
%
% - par is a subject and task-specific structure with information about the
% recording
% - elecs is a vector of channel numbers for which you want to get amplitude and phase
% - lo/hicutoff are equal-length vectors of frequency bands from which to get
% amplitude and phase
%
% This function is the same as ecogDataDecompose, except that you can pass
% in certain frequency bands.
%

% use eeglab package

if notDefined('locutoff'), locutoff= [1 4 8 15 30 80 30]; end
if notDefined('hicutoff'), hicutoff= [4 7 12 25 80 180 180]; end
freq= [locutoff;hicutoff];
block_name= par.block;
fs_comp= par.fs_comp;
compression= par.compression;
chanLength= par.chanlength;
iEEG_rate= par.ieegrate;

for ci= elecs
    band=[];
    band.elec= ci;
    band.freq= freq;
    band.block_name= block_name;
    load(sprintf('%s/CARiEEG%s_%.2d.mat',par.CARData,block_name, ci));
    wave= double(wave);
    input= decimate(wave,compression,'FIR');% Down-sampling 
    clear wave
    
    amplitude= zeros(size(freq,2),ceil(chanLength/compression),'single');
    phase= zeros(size(freq,2),ceil(chanLength/compression),'single');
   
    
    for fi=1:size(freq,2)       
        disp([ci freq(1,fi) freq(2,fi)])
        %fc= (freq(1,fi) + freq(2,fi) )/2; % central frequency
        %filtorder= floor(fs_comp*2/fc); % filter order -- amr: not sure what this is used for in some newer version of ecogBandPass
        % bandpass the data for each freq
        tmp= ecogBandPass(input ,fs_comp, freq(1,fi), freq(2,fi),1); % ecogBandPass(input ,fs_comp, freq(1,fi), freq(2,fi),0,filtorder);
        %tmp= eegfilt(input ,fs_comp, freq(1,fi), freq(2,fi),0,filtorder); % ecogBandPass(input ,fs_comp, freq(1,fi), freq(2,fi),0,filtorder);
        % Envelope of signal
        analytic= hilbert(tmp);
        amplitude(fi,:)= single(abs(analytic));
        phase(fi,:)= single(angle(analytic));

    end
    band.amplitude= amplitude;
    band.phase= phase;
    save(sprintf('%s/band_%s_%.3d',par.SpecData,block_name,ci),'band')
    
    clear input
end