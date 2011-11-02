function stdev = ecogStdev(par,startstamps,endstamps,elecs)
% stdev = ecogStdev(par,startstamps,endstamps)
%
% jc 04/04/11
%

% Update path info based on par.basepath
par = ecogPathUpdate(par);

%% handle different input specifications...
if ~exist('elecs','var')
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

%% Calculate stdev for each channel

for ci= elecs;
    fprintf(['\nCalculating Stdev for ' par.block ' electrode ' num2str(ci) '\n']);
    
    load(sprintf('%s/CARiEEG%s_%.2d',par.CARData,par.block,ci));
    
    
    % Concatenate waveform sections
    keptwave = [];
    for fi=1:length(startstamps)
        
        % event points
        start_point = floor(startstamps(fi) * par.ieegrate);
        end_point = floor(endstamps(fi) * par.ieegrate);
        keptwave = [keptwave wave(start_point:end_point)];
    end

    stdev(ci).std = std(keptwave);
    stdev(ci).wave = keptwave;
    stdev(ci).startstamps = startstamps;
    stdev(ci).endstamps = endstamps;
    
end

fn= sprintf('%s',par.Results);
save(sprintf('%s/stdev_%s_%s.mat',fn,par.exptname,par.block),'stdev');

