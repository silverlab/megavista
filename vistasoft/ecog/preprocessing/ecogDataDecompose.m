function []= ecogDataDecompose(par,elecs,overwrite)
% Function: decomposing signal into Amplitude and Phase for different
% frequencies
% Input: CAR data
% ouput: per channel, amplitude and phase matrix 
% Dependencies; signal processing tooolbox, band_pass.m
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford rev. SEP,2009
% modified j.chen jan 2010

% Update path info based on par.basepath
par = ecogPathUpdate(par);

if ~exist('elecs','var') 
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

if ~exist('overwrite','var')
    overwrite = 0;
end

for ci= elecs

    if (~exist(sprintf('%s/amplitude_%s_%.3d.mat',par.SpecData,par.block,ci))) || (overwrite==1)
        load(sprintf('%s/CARiEEG%s_%.2d.mat',par.CARData,par.block, ci));
        wave  = double(wave);
        input = fft(wave,[],2); % FFT transform
        clear wave
        amplitude = zeros(length(par.freq),ceil(par.chanlength/par.compression),'single');
        phase = zeros(length(par.freq),ceil(par.chanlength/par.compression),'single');

        fprintf(['\nelec: ' num2str(ci) ' freq: ']);
        for fi=1:length(par.freq)
            f= par.freq(fi);
            fprintf([num2str(fi) ' ']);
            % bandpass the data for each freq
            tmp= ecogBandPass(input,par.ieegrate ,f-0.1*f, f+0.1*f, 0);
            analytic= hilbert(tmp);
            amplitude(fi,:)= single(decimate(abs(analytic),par.compression,'FIR'));
            phase(fi,:)= single(decimate(angle(analytic),par.compression,'FIR'));

        end
        save(sprintf('%s/amplitude_%s_%.3d',par.SpecData,par.block,ci),'amplitude')
        save(sprintf('%s/phase_%s_%.3d',par.SpecData,par.block,ci),'phase')

        clear input
    else
        fprintf(['amplitude & phase files already exist for elec ' num2str(ci) ', skipping calculation\n']);
    end
end
