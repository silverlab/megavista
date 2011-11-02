function [x,y,stdDev] =  mmEyeSimulation(nOutputs,fName)
% Simulate Mike May's eye movement patterns
%
%  [x,y,stdDev] =  mmEyeSimulation(nOutputs,fName)
%
% nOutputs is the number of temporal samples for outputs, x,y
% 
%  We experimented with the wx weights and s to try to match the published
%  data in the Fine Nature Neuroscience article.  These values were pretty
%  close. So we stopped.
% 
% Example:
%  nOutputs = 133;
%  [x,y,stdDev] = mmEyeSimulation(nOutputs);
%  figure; plot(x); hold on; plot(y,'r-');set(gca,'ylim',[-15 15]); grid on
%  fName = ['Stimuli/jitter',num2str(nOutputs),'.mat']; save(fName,'x','y')
%
% Or,
%   fName = ['Stimuli/jitter',num2str(nOutputs),'.mat'];
%   [x,y,stdDev] = mmEyeSimulation(nOutputs, fName);
%

%% Yes, we know this is a hack

if nOutputs > 150, error('Max output samples: 150'); end


%% Initialize variables
nSamp = 150;
nSamp = nSamp*2;     % 2x the number of samples to avoid symmetry
p = (1:nSamp)/nSamp;
x = zeros(1,nSamp); y = x;

%% Build the frequency weights to try to match MM's data from the 2003
% article
wx = (1./(1:nSamp)).^0.3 .* (0.5*randn(1,nSamp));
wy = (1./(1:nSamp)).^0.3 .* (0.5*randn(1,nSamp));

% The high frequency terms were a bit small and the mid-frequencies were a
% bit large
A = 2; B = 125; C = round(nSamp/2); 
s = [2*ones(1,A),linspace(1,0.3,B-A),linspace(0.3,3,C-B)];
s = [s fliplr(s)];
s = s(1:nSamp);

wx = wx .* s;
wy = wy .* s;
% plot(cos(2*pi*63*p))

%% add up the cosine terms
for f=1:round(nSamp/2)
    x = x + wx(f)*cos(2*pi*f*p);
    y = y + wy(f)*cos(2*pi*f*p);
end

%% Reduce the samples to the requested number
x = x(1:nOutputs);
y = y(1:nOutputs);

%% Store the standard deviations
stdDev.x = std(x);
stdDev.y = std(y);

%%
if notDefined('fName'), return;
else                    save(fName,'x','y');
end

return;

%

