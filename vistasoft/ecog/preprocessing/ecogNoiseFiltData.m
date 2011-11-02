function []=ecogNoiseFiltData(par,elecs)
% Filtering 60 Hz line noise
% Dependencies:notch.m .eeglab toolbox
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Revision date SEP,2009
%
% This function will save out each notch-filtered channel separately into the FiltData
% directory, and it will also save allChanNotch, which is a compressed
% version of all the channels.
%
% Modified j.chen Dec 2009

% Update path info based on par.basepath
par = ecogPathUpdate(par);

fprintf('Starting Filtering\n');
if ~exist('elecs','var') 
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));
% % don't bother with badchans and epichans
% elecs=elecs(~ismember(elecs,par.epichan));
% elecs=elecs(~ismember(elecs,par.badchan));

allChanNotch = zeros(par.nchan,ceil(par.chanlength/par.compression),'single');
for ci = elecs
    fname = sprintf('%s/fiEEG%s_%.2d.mat',par.FiltData,par.block,ci);
if exist(fname,'file')
    fprintf(['Filtered file already exists for electrode ' num2str(ci) '\n']);
else
    % load the raw wave
    rawvar = load(fullfile(par.RawData,par.rawfilenames{ci}));
    rawvarname = cell2mat(fieldnames(rawvar)); 
    wave = rawvar.(rawvarname);
    clear rawvar
    % filtering 60 Hz
    wave = ecogNotch(wave, par.ieegrate, 59, 61,1);
    wave = ecogNotch(wave, par.ieegrate, 118,122,1); % Second harmonic of 60
    wave = ecogNotch(wave, par.ieegrate, 178,182,1); % Third harmonic of 60
    % saving filtered data
    save(sprintf('%s/fiEEG%s_%.2d.mat',par.FiltData,par.block,ci),'wave')
    % saving compressed filtered data, each channel
    allChanNotch(ci,:) = single(ecogCompressSignal(wave,par.compression));
    clear wave
    fprintf('%.2d of %.3d channels\n',ci,par.nchan)
end
end
save(sprintf('%s/allChanNotch%s.mat',par.CompData,par.block),'allChanNotch');
fprintf('Filtering and compression are done and saved \n')
