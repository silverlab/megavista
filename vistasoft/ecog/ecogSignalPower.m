% Power of Siganl

% Reading Globals
block_name= 'ST07-03';
load(sprintf('globalVar/global_%s',block_name));
% VAROUT 'block_name','sbj_name','nchan','badChan','refChan','iEEG_rate','Pdio_rate',...
% VAROUT 'numEvents', 'chanLength', 'data_dir','result_dir','CAR_dir','event_dir'

% variables
ci= 20; % Channel Number
ei=7; % Event number

% Loading data
numSamples=[];
load(sprintf('%s/event%.2d/chan%.3d/numSamples.mat',event_dir,ei,ci));
sampleLength= zeros(1,numSamples);
for si=1:numSamples
    load(sprintf('%s/event%.2d/chan%.3d/event%.2d_chan%.3d_rep%.3d.mat',event_dir,ei,ci,ei,ci,si))
end

ff=[];
power= zeros(numSamples,34);
freq= zeros(numSamples,34);
for si=1: numSamples
    tmp= double(eval(sprintf('event%.2d_chan%.3d_rep%.3d',ei,ci,si)));
    [pxx,w] =pwelch(tmp);
    f= w*(iEEG_rate/2)/pi;
    pxx= pxx/max(pxx);
    pxn= resample(pxx(f<100),34,length(pxx(f<100)));
    fn= resample(f(f<100),34,length(f(f<100)));
    %figure(si), plot( f(f<100),pxx(f<100))
    %ff= [ff length(f(f<100))];
    power(si,:)= pxn;
    freq(si,:)= fn;
end
meanPower= mean(power);
stdPower= std(power);
meanFreq= mean(freq);
% stdFreq= std(freq);

figure,
errorbar(meanFreq,meanPower,stdPower/sqrt(numSamples),'-o','LineWidth',2)
xlim([0 95]); ylim([-.1 1])
xlabel('frequency (Hz)','FontSize',16)
ylabel('average spectral density','FontSize',16)
title(sprintf('channel: %d condition: %d',ci, ei),'FontSize',14)