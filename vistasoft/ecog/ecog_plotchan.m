
function plotchan(chan,varargin)

colors = 'grbmck';
figure(gcf);
for n = 1:length(varargin)
    eval(['data' num2str(n) '= varargin{n};']);
    eval(['plot(data' num2str(n) '(' num2str(chan) ',:),''' colors(n) ''')']);
    hold on
end

% It would be good for plotting purposes to have the srate and prestimdur,
% then plot the waveforms shifted by prestimdur so that x=0 corresponds to
% time=0. As long as srate = 1000.

% chanmin = min(data1(1,:));
% chanmax = max(data1(1,:));
% zeropnt = EEG.srate * prestimdur;
% plot([zeropnt zeropnt],[chanmin chanmax],'k-');

end