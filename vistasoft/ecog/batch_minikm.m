
function batch

exptname = 'minikm';

%% miniKM paths:

% raw ecog and behavioral files are located on biac or kanile?
dataloc = 'biac';

switch dataloc
    case 'biac'
        ecog_basepath = '/Volumes/kanile/wandell7/data/ECoG/ecog02/ecog/miniKM';
        behpath = '/Volumes/kanile/wandell7/data/ECoG/ecog02/ecog/miniKM/behavioral';
        savepath = fullfile(ecog_basepath,'analysis');
    case 'kanile'
        ecog_basepath = '/Volumes/kanile/wandell7/data/ECoG/ecog02/ecog/miniKM';
        behpath = '/matlab_users/Janice/miniKM/data/ecog02/behavioral';
        savepath = '/matlab_users/Janice/miniKM/data/ecog02/behavioral/analysis';
end

%% Parameters

% defaults
analogChan = 'analog_4';  % photodiode channel is different for every patient
chanlist = [1:56];
samplerate = 3051.76;
analog_samprate = 3051.76;
resamplerate = samplerate;

% choose a block:
block = 'ST03_bl76'
switch block
    case 'ST03_bl16'
        tfile = 'kmData.oct.27.10.2008.10.30.mat.txt';
    case 'ST03_bl19'
        tfile = 'kmData.oct.27.10.2008.10.59.mat.txt';
    case 'ST03_bl34'
        tfile = 'kmData.oct.27.10.2008.17.17.mat.txt';
    case 'ST03_bl35'
        tfile = 'kmData.oct.27.10.2008.17.26.mat.txt';
    case 'ST03_bl76'
        tfile = 'kmData.oct.29.10.2008.11.34.mat.txt';
        analog_samprate = 24414.1;
end
blockpath = fullfile(ecog_basepath,block);
savename = [exptname '.' block];

prestimdur = 0.1; % seconds
epochmax = 1.1;

% Which steps do you want to execute?
doTimestamps = 1;
doGdat = 0;
doEEGstruct = 0;
doReref = 0;
doFilter = 0;
doEpoch = 0;

%% Process data, saving files at each step

% Assign timestamps
if doTimestamps
    [truestamps,firstEvent,conds] = stampfunc(blockpath,behpath,analogChan,...
        samplerate,analog_samprate,tfile);
    %-- save
    stampspath = fullfile(savepath,[savename '.stamps.mat']);
    save(stampspath,'truestamps','firstEvent','conds');
end

% Read gdat files
%-- load needed params from saved file if necessary
if doGdat
    if ~exist('truestamps','var')
        load(fullfile(savepath,[savename '.stamps.mat']));
    end
    %-- read the gdat files
    dat = readgdat(blockpath,chanlist,samplerate);
    %-- save
    gdatpath = fullfile(savepath,[savename '.gdat_all.mat']);
    save(gdatpath,'dat');
end

% Create EEGlab struct
if doEEGstruct
%-- load needed params from saved file if necessary
if ~exist('truestamps','var')
    load(fullfile(savepath,[savename '.stamps.mat']));
end
%-- create the struct
gdatpath = fullfile(savepath,[savename '.gdat_all.mat']);
origEEG = createEEG(truestamps,firstEvent,conds,gdatpath,chanlist,samplerate,resamplerate);
%-- save
origEEGpath = fullfile(savepath,[savename '.origEEG.mat']);
save(origEEGpath,'origEEG');  % this file can be loaded for use with EEGlab functions without GUI
pop_saveset(origEEG, 'filename', [savename '.set'], 'filepath', savepath);
end

% Rereference
if doReref
end


% Filter
if doFilter
end

% Epoch
if doEpoch
    %-- load needed params from saved file if necessary
    if ~exist('origEEG','var')
        load(fullfile(savepath,[savename '.origEEG.mat']));
    end
    %-- epoch the data
    epochs = kmepochfunc(origEEG,prestimdur,epochmax);
    %-- save
    epochpath = fullfile(savepath,[savename '.epochs.mat']);
    save(epochpath,'epochs');
end

end

%% Subfunctions...

%% Epoch
function epochs = kmepochfunc(origEEG,prestimdur,epochmax)

% Baseline sequence: Conditions 11,12,13,14
EEG = pop_epoch( origEEG, {'11'}, [-1*prestimdur epochmax], 'newname', 'base11', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
epochs.base(1).data = EEG.data;
EEG = pop_epoch( origEEG, {'12'}, [-1*prestimdur epochmax], 'newname', 'base12', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.base(2).data = EEG.data;
EEG = pop_epoch( origEEG, {'13'}, [-1*prestimdur epochmax], 'newname', 'base13', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.base(3).data = EEG.data;
EEG = pop_epoch( origEEG, {'14'}, [-1*prestimdur epochmax], 'newname', 'base14', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.base(4).data = EEG.data;

% First (1st 4 objs in Rep, Half, New): 1,2,3,4
EEG = pop_epoch( origEEG, {'1'}, [-1*prestimdur epochmax], 'newname', 'first1', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
epochs.first(1).data = EEG.data;
EEG = pop_epoch( origEEG, {'2'}, [-1*prestimdur epochmax], 'newname', 'first2', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.first(2).data = EEG.data;
EEG = pop_epoch( origEEG, {'3'}, [-1*prestimdur epochmax], 'newname', 'first3', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.first(3).data = EEG.data;
EEG = pop_epoch( origEEG, {'4'}, [-1*prestimdur epochmax], 'newname', 'first4', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.first(4).data = EEG.data;

% Repeated: 21,22,23,24
EEG = pop_epoch( origEEG, {'21'}, [-1*prestimdur epochmax], 'newname', 'rep21', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
epochs.rep(1).data = EEG.data;
EEG = pop_epoch( origEEG, {'22'}, [-1*prestimdur epochmax], 'newname', 'rep22', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.rep(2).data = EEG.data;
EEG = pop_epoch( origEEG, {'23'}, [-1*prestimdur epochmax], 'newname', 'rep23', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.rep(3).data = EEG.data;
EEG = pop_epoch( origEEG, {'24'}, [-1*prestimdur epochmax], 'newname', 'rep24', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.rep(4).data = EEG.data;

% Half: 31,32,33,34
EEG = pop_epoch( origEEG, {'31'}, [-1*prestimdur epochmax], 'newname', 'half31', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
epochs.half(1).data = EEG.data;
EEG = pop_epoch( origEEG, {'32'}, [-1*prestimdur epochmax], 'newname', 'half32', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.half(2).data = EEG.data;
EEG = pop_epoch( origEEG, {'33'}, [-1*prestimdur epochmax], 'newname', 'half33', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.half(3).data = EEG.data;
EEG = pop_epoch( origEEG, {'34'}, [-1*prestimdur epochmax], 'newname', 'half34', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.half(4).data = EEG.data;

% New: 41,42,43,44
EEG = pop_epoch( origEEG, {'41'}, [-1*prestimdur epochmax], 'newname', 'new41', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]); % baseline: [-100 0] milliseconds
epochs.new(1).data = EEG.data;
EEG = pop_epoch( origEEG, {'42'}, [-1*prestimdur epochmax], 'newname', 'new42', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.new(2).data = EEG.data;
EEG = pop_epoch( origEEG, {'43'}, [-1*prestimdur epochmax], 'newname', 'new43', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.new(3).data = EEG.data;
EEG = pop_epoch( origEEG, {'44'}, [-1*prestimdur epochmax], 'newname', 'new44', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-1*prestimdur*1000 0]);
epochs.new(4).data = EEG.data;

fprintf(['\nTrials per condition:\n']);
fprintf(['Base: ' num2str(size(epochs.base(1).data,3)) '\n']);
fprintf(['First: ' num2str(size(epochs.first(1).data,3)) '\n']);
fprintf(['Repeated: ' num2str(size(epochs.rep(1).data,3)) '\n']);
fprintf(['Half: ' num2str(size(epochs.half(1).data,3)) '\n']);
fprintf(['New: ' num2str(size(epochs.new(1).data,3)) '\n']);

end

%%




