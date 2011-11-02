function []= ecogCompressData(par,elecs)
%
% function []= ecogCompressData(par,elecs)
%
% Usage:
% ecogCompressData(par,[1 2 3])
%
% Dependencies:compressSignal
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Revision date SEP,2009
% Modified j.chen Dec 2009
%
if ~exist('elecs','var') 
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

% Compressing data before referencing
if nargin==1
    elecs= setxor([1:par.nchan],[par.refchan]);
    allChan= zeros(par.nchan,ceil(par.chanlength/par.compression),'single');
    for ci= elecs
        load(fullfile(fileparts(par.rawData),par.block,['gdat_' num2str(ci)]))
        wave = eval(['gdat_' num2str(ci)]);
        clear gdat*
        allChan(ci,:)= single(ecogCompressSignal(wave,par.compression));
        clear wave
        fprintf('%.2d of %.3d channels\n',ci,par.nchan)
    end
    save(sprintf('%s/allChan%s.mat',par.CompData,block),'allChan');
    fprintf('Compression is done and saved \n')
else
    allChan= zeros(par.nchan,ceil(par.chanlength/par.compression),'single');
    for ci= elecs
        %load(sprintf('%s/iEEG%s_%.2d.mat',par.data_dir,block_name,ci)); %wave
        load(fullfile(fileparts(par.rawData),block,['gdat_' num2str(ci)]))
        wave = eval(['gdat_' num2str(ci)]);
        clear gdat*
        allChan(ci,:)= single(ecogCompressSignal(wave,par.compression));
        clear wave
        fprintf('%.2d of %.3d channels\n',ci,par.nchan)
    end
    save(sprintf('%s/allChan%s.mat',par.CompData,block),'allChan');
    fprintf('Compression is done and saved \n') 
end
