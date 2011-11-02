function [filt_signal]=notch(input, sampling_rate, lower_bound, upper_bound, tm_OR_fr)
%  [filt_signal]=bandpass(input, sampling_rate, lower_bound, upper_bound, tm_OR_fr)
%     input         - input signal to be filtered (time or frequency domain)
%     sampling_rate - signal's sampling rate
%     lower_bound     - lower frequency bound for bandpass filtering
%     upper_bound   - upper frequency bound for bandpass filtering
%     tm_OR_fr      - 1 if the input signal is in the time domain, 0 if it
%                     is in the frequency domain
%
%  The function returns the filtered signal (low->high) in the time domain
%  Written by Robert Knight lab members (Adeen Flinker)

    if (nargin<5)
        tm_OR_fr=1;
    end
    if (nargin<4)
        error('Please enter at least 4 arguments');
    end

    max_freq=sampling_rate/2;
    df=2*max_freq/length(input);
    centre_freq=(upper_bound+lower_bound)/2;
    filter_width=upper_bound-lower_bound;
    x=0:df:max_freq;
    gauss=exp(-(x-centre_freq).^2*10);
    cnt_gauss = round(centre_freq/df);
	flat_padd = 0;%round(filter_width/df);  % flat padding at the max value of the gaussian
	padd_left = floor(flat_padd/2);
	padd_right = ceil(flat_padd/2); 
	our_wind = 1-[gauss((padd_left+1):cnt_gauss) ones(1,flat_padd) gauss((cnt_gauss+1):(end-padd_right))];
    if (mod(length(input),2)==0)
        our_wind = [our_wind(1:(end-1)) fliplr(our_wind(1:(end-1)))];
    else
        our_wind = [our_wind fliplr(our_wind(1:(end-1)))];        
    end
    
	if (tm_OR_fr==1)
        input=fft(input,[],2);
    end
    %plot(our_wind)
    our_wind = repmat(our_wind,size(input,1),1);
    filt_signal=ifft(input.*our_wind,[],2,'symmetric');
end

    
    

