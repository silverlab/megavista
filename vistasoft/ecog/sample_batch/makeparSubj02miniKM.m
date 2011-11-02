
function par = makeparSubj02miniKM(block,basepath,parfilepath)
% Written by Mohammad Dastjerdi, Parvizi Lab, Stanford- Revision date SEP,2009
% Modified by j.chen Dec 2009

%% Variables
par.subjname= 'subj02';
par.exptname = 'miniKM';
par.block = block;
par.nchan= 56; % 56
par.pdiochan = 'analog_4';
par.rawprefix = 'gdat';

par.badchan = [9 10 20 45 46];
par.refchan = [30];
par.epichan = [11 12 13 14 23 24 32 33];
par.ieegrate= 3051.76;
par.pdiorate= 3051.76;
par.compression= 7;

% Choose the event file and set idiosyncratic block parameters:
switch block
    case 'ST03_bl16'
        par.eventfile = 'kmData.oct.27.10.2008.10.30.mat.txt';
        par.missingchan = 15;
    case 'ST03_bl19'
        par.eventfile = 'kmData.oct.27.10.2008.10.59.mat.txt';
    case 'ST03_bl34'
        par.eventfile = 'kmData.oct.27.10.2008.17.17.mat.txt';
    case 'ST03_bl35'
        par.eventfile = 'kmData.oct.27.10.2008.17.26.mat.txt';
    case 'ST03_bl76'
        par.eventfile = 'kmData.oct.29.10.2008.11.34.mat.txt';
        par.pdiorate= 24414.1;
end


%% Reading a list of ictal activities otherwise is empty
for ii=1:par.nchan
    par.ictal{ii}= NaN* ones(2,1); % start and end
end

%% Set directories created outside of this function
par.RawData = fullfile(basepath,'RawData',block);
par.BehavData = fullfile(basepath,'BehavData');

%% Create analysis directories if needed
dir_names = {'CARData','CompData','FiltData','RerefData','SpecData','Results','Print'};
% Directory contents:
% CARData: Common average referencing (CAR)
% CompData: Compiled data, all chans in one mat
% FiltData: Notch filtered data
% reRefData: Rereferenced data
% SpecData: Spectral data

for n = 1:length(dir_names)
    newdir = fullfile(basepath,dir_names{n});
    newblock = fullfile(basepath,dir_names{n},block);
    if ~exist(newdir,'dir')
        mkdir(basepath,dir_names{n});
    end
    if ~exist(newblock,'dir')
        mkdir(fullfile(basepath,dir_names{n}),block)
    end
    par.(dir_names{n}) = newblock;
end

% populate list of raw filenames
cd(par.RawData);
d = dir([par.rawprefix '*']);
rawmatcell = strrep({d(:).name},[par.rawprefix '_'],'');
elecnumcell = strrep(rawmatcell,'.mat','');
rawelecind = str2num(strvcat(elecnumcell{:}));
par.rawfilenames(rawelecind) = {d(:).name};

%% The number of sample points in a channel
rawvar = load(fullfile(par.RawData,par.rawfilenames{1})); 
par.rawvarname = cell2mat(fieldnames(rawvar)); % sometimes gdat_*, sometimes wave
par.chanlength= length(rawvar.(par.rawvarname));

%% Frequencies for spectral analysis and the compression
freq = ecogCreateFreqs(1,250,0.8); % [from 1 to 229 Hz] (1,250,0.8)
fs_comp= ceil(par.chanlength/par.compression)/(par.chanlength/par.ieegrate); % frequency= (number of points) / time
par.freq= freq;
par.fs_comp= fs_comp;

%% Saving par 
if exist(parfilepath)
    fprintf('par file exists - making backup\n');
    movefile(parfilepath, [parfilepath(1:end-3) date '.mat']);
end
save(parfilepath,'par');


