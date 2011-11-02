function freqs = ecogCreateFreqs(min_f,max_f,min_delta,log_spacing)
%   freqs = create_freqs(min_f,max_f,min_delta,log_spacing);
%       The function returns a logarithmical space between min_f and max_f
%       where min_delta is the minimum spacing between each entry
%

%   log_spacing - parameter which defines the spacing in the logarithmical
%                  plane
% Written by Adeen Flinker , Robert knight Lab, UCB

if nargin < 4   , log_spacing = 0.04;  end
if nargin < 3   , min_delta = 0.8;     end
if nargin < 2   , help create_freqs;
    error('Must provide at least 2 arguments'); end

x = log10(min_f):log_spacing:log10(max_f);
freqs = 10.^x;
i=2;
while (i<=length(freqs))
    if ((freqs(i)-freqs(i-1))<min_delta)
        freqs = [freqs(1:(i-1)) freqs((i+1):end)];
    else
        i = i+1;
    end
end

dl=[];
for ii= 1:length(freqs)
    if freqs(ii)>55 & freqs(ii)<65
        dl= [dl ii];
    end
end
freqs(dl)=[];