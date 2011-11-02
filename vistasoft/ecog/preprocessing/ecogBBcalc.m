function []= ecogBBcalc(par,elecs,minfreq,maxfreq)
% j.chen apr 2011

% Update path info based on par.basepath
par = ecogPathUpdate(par);

if ~exist('elecs','var')
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

for ci= elecs
    
    load(sprintf('%s/CARiEEG%s_%.2d.mat',par.CARData,par.block, ci));
    wave= double(wave);
    input= fft(wave,[],2); % FFT transform
    clear wave
    
    fprintf(['elec: ' num2str(ci) '\n']);
    
    % bandpass the data: two alternatives
    
    % ecogBandPass is faster, ok for everyday use
    tmp= ecogBandPass(input,par.ieegrate, minfreq, maxfreq, 0);
    
    % eegfilt takes longer, use this before publication
    %  tmp= eegfilt(wave,par.ieegrate, minfreq, maxfreq);
    
    analytic= hilbert(tmp);
    bb= single(decimate(abs(analytic),par.compression,'FIR'));
    
    save(sprintf('%s/bbiEEG_%s_%.3d_%.3d_%.3d',par.BBData,par.block,minfreq,maxfreq,ci),'bb')
    
    %     % plot the power spectrum
    %     load(sprintf('%s/CARiEEG%s_%.2d.mat',par.CARData,par.block, ci));
    %
    %     N = length(wave);
    %     T = N/par.ieegrate; % length of wave in seconds
    %     t = (0:N-1)/N;
    %     t = t*T; % vector of timepoints in seconds
    %     p = abs(fft(wave))/(N/2); % abs value of the fft
    %     p = p(1:N/2) .^ 2; % calc the power of the positive freq half
    %     freqs = [0:(N/2)-1]/T; % find the corresponding freq in Hz
    %     f2 = resample(freqs(freqs<100),1,7);
    %     p2=double(p);
    %     p2 = resample(p2(freqs<100),1,7);
    %     semilogy(f2,p2);
end



