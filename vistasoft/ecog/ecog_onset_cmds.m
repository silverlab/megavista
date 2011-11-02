
thresh = 0.5 * max(analog_3);
index=find(a3>1*10^-6);

figure(1); clf;
% plot(gdat_1,'b');
hold on
plot(analog_3,'r');
plot(index,thresh,'gx');

% sampling rate: 3051.76 Hz

% write a script to identify first exptl onset
% maybe take advantage of the initial flashes
% but include a step for "human" validation