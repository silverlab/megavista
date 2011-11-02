function []= ecogCommonAvgRef(par,str,elecs)
% Rereferencing to a Common Average Reference
% str variable is 'orig' or 'noiseFilt' or 'artRep'
% Dependencies:
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Revision date SEP,2009
% Modified j.chen Dec 2009

% Update path info based on par.basepath
par = ecogPathUpdate(par);

%% Removing Bad Channels
% The reference, epileptic and "bad" channels should never be included in
% the CAR. However, we do want to subtract the CAR from everything BUT the
% reference. So, keep channels that will go into the CAR in "CARelecs", while
% the resulting CAR will be subtracted from all channels in "elecs" (except reference).
if ~exist('elecs','var')
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));
CARelecs=elecs(~ismember(elecs,par.epichan));
CARelecs=CARelecs(~ismember(CARelecs,par.badchan));

cnt= length(CARelecs);

%% Calculate CAR

if strcmp(str,'orig')
    fprintf('Making CAR from original data\n')
elseif strcmp(str,'noiseFilt')
    fprintf('Making CAR from notch filtered data\n')
elseif strcmp(str,'artRep')
    fprintf('Making CAR from notch filtered and artifact-rejected data\n')
else
    error('str variable should be orig, noiseFilt, or artRep')
end
fprintf('Making CAR\n')
%% Calculating Common Average Reference
CAR = zeros(1,par.chanlength,'single');
for ci = CARelecs
    if strcmp(str,'orig')
        % load the raw wave
        fprintf(['Reading: ' fullfile(par.RawData,par.rawfilenames{ci}) '\n']);
        rawvar = load(fullfile(par.RawData,par.rawfilenames{ci}));
        rawvarname = cell2mat(fieldnames(rawvar));
        wave = rawvar.(rawvarname);
        clear rawvar
    elseif strcmp(str,'noiseFilt')
        fprintf(['Reading: ' sprintf('%s/fiEEG%s_%.2d.mat',par.FiltData,par.block,ci) '\n']);
        load(sprintf('%s/fiEEG%s_%.2d.mat',par.FiltData,par.block,ci)); % contains "wave" var
    elseif strcmp(str,'artRep')
        fprintf(['Reading: ' sprintf('%s/aiEEG%s_%.2d.mat',par.ArtData,par.block,ci) '\n']);
        load(sprintf('%s/aiEEG%s_%.2d.mat',par.ArtData,par.block,ci)); % contains "wave" var
    end
    wave = wave - mean(wave);                    % remove mean before CAR
    CAR = CAR + wave;             % sum CAR in groups
    clear wave
end

CAR= CAR/cnt; % common average reference
save(sprintf('%s/CAR%s.mat',par.CARData,par.block),'CAR','CARelecs');

% figure, plot((1:length(CAR))/iEEG_rate,CAR/cnt),hold on
% plot((1:length(CAR))/iEEG_rate,wave)

%% Subtracting the common average reference from all channels
fprintf('Subtracting CAR from data\n')
for ii = elecs
    if strcmp(str,'orig')
        fn = sprintf('%s/iEEG%s_%.2d.mat',par.RawData,par.block,ii);
    elseif strcmp(str,'noiseFilt')
        fn = sprintf('%s/fiEEG%s_%.2d.mat',par.FiltData,par.block,ii);
    elseif strcmp(str,'artRep')
        fn = sprintf('%s/aiEEG%s_%.2d.mat',par.ArtData,par.block,ii);
    end
    ['Reading: ' fn]
    load(fn);
    avgbeforeCAR(ci) = mean(wave);
    
    wave = wave - CAR;
    ['Writing: ' sprintf('%s/CARiEEG%s_%.2d.mat',par.CARData,par.block, ii)]
    save(sprintf('%s/CARiEEG%s_%.2d.mat',par.CARData,par.block, ii),'wave');
    avgafterCAR(ci) = mean(wave);
    clear wave 
end

save(sprintf('%s/chanavgs_%s.mat',par.CARData,par.block),'avgbeforeCAR','avgafterCAR');
