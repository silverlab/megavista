
function par = makeparSubj13VISTA(block,basepath,parfilepath)
% j.chen 2010

%% Variables
par.subjname= 'kp';
par.exptname = 'AIN';
par.block = block;
par.nchan= 48;
par.pdiochan = ['Pdio' block '_02']; % PdioAC0210_02.mat
par.rawprefix = 'iEEG'; % iEEGAC0210_16.mat

% "bad" and epileptic channels are both removed from CAR, but epileptic
% channels will go on to be analyzed.

par.elecsubset = 'conservative';
switch par.elecsubset
    case 'liberal'
        par.badchan = []; 
        par.epichan = [];
    case 'conservative'
        par.keptchan = [1,4:8,9,14:16,17:18,20:24,25:32,33,36:40,44:48]; % keep these for CAR
        par.epichan = [10 11 12 19 34 35 41:43]; % also analyze these channels
        par.badchan = setdiff([1:par.nchan],[par.keptchan par.epichan]);
end

par.refchan = 25; % (RA1)
par.ieegrate= 3051.76; 
par.pdiorate= 24414.1; 
par.compression= 7;
par.rejelecs = [9 17 18 33 35];

% Choose the event file and set idiosyncratic block parameters:
switch block
    case 'KP1010-02'
        par.eventfile = 'ain.kp.1.out.txt';
    case 'KP1010-03'
        par.eventfile = 'ain.kp.2.out.txt';
    case 'KP1010-04'
        par.eventfile = 'ain.kp.3.out.txt';
    case 'KP1010-05'
        par.eventfile = 'ain.kp.4.out.txt';
    case 'KP1010-06'
        par.eventfile = 'ain.kp.5.out.txt';
    case 'KP1010-07'
        par.eventfile = 'ain.kp.6.out.txt';
    case 'KP1010-08'
        par.eventfile = 'ain.kp.7.out.txt';
    case 'KP1010-09'
        par.eventfile = 'ain.kp.8.out.txt';
    case 'KP1010-10'
        par.eventfile = 'ain.kp.9.out.txt';
    case 'KP1010-11'
        par.eventfile = 'ain.kp.11.out.txt';
end


%% Reading a list of ictal activities otherwise is empty
for ii=1:par.nchan
    par.ictal{ii}= NaN* ones(2,1); % start and end
end

%% Set directories created outside of this function
par.RawData = fullfile(basepath,'RawData',block);
par.BehavData = fullfile(basepath,'BehavData');

%% Create analysis directories if needed
dir_names = {'ArtData','CARData','CompData','FiltData','RerefData','SpecData','Results','Print'};
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

%% For analyses of different subsets of elecs, create subdirectories in
%  Results and CARData
% if isfield(par,'elecsubset')
%     par.Results = fullfile(par.Results,par.elecsubset);
%     par.CARData = fullfile(par.CARData,par.elecsubset);
% end

% populate list of raw filenames
cd(par.RawData);
d = dir([par.rawprefix '*']);
prefix = d(1).name(1:regexp(d(1).name, '\d*.mat')-1);
rawmatcell = strrep({d(:).name},prefix,'');
elecnumcell = strrep(rawmatcell,'.mat','');
rawelecind = str2num(strvcat(elecnumcell{:}));
par.rawfilenames(rawelecind) = {d(:).name};

% output warning if rawelecind was not populated
if isempty(rawelecind)
    fprintf('\n Warning: Electrode filenames may not have populated correctly \n\n Check that electrode filenames are in ascending numerical order \n\n.')
    display(par.rawfilenames');    
end

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


