function outputmat=XCR_spect(EEGdata,eventdata,srate,freqH,freqL,Tbefore,Tafter)
ffteventdata=fft(fliplr(eventdata));
fftEEGdata=fft(EEGdata);
max_freq=srate/2;
df=2*max_freq/length(EEGdata);
x=0:df:max_freq;

for f=1:length(freqH)
    centre_freq=(freqH(f)+freqL(f))/2;
    filter_width=freqH(f)-freqL(f);
    gauss=exp(-(x-centre_freq).^2);
    cnt_gauss = round(centre_freq/df);
    flat_padd = round(filter_width/df);  % flat padding at the max value of the gaussian
    padd_left = floor(flat_padd/2);
    padd_right = ceil(flat_padd/2);
    our_wind = [gauss((padd_left+1):cnt_gauss) ones(1,flat_padd) gauss((cnt_gauss+1):(end-padd_right))];
    filtwind=[our_wind zeros(1,length(EEGdata)-length(our_wind))];

    fftanamp=fft(abs(ifft(fftEEGdata.*filtwind)));
    mat=fftshift(ifft(fftanamp.*ffteventdata));

    ser=mat(ceil(length(mat/2)*rand(1,3000)));
    outputmat(f,:)=(mat(round(end/2-Tafter*srate):round(end/2+Tbefore*srate))-mean(ser))/std(ser);
end



return