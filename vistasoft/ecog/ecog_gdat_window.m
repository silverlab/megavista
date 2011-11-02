
function gdat_window(xmin,xmax,gdat_samplerate,analog_samplerate,gdat_path,new_path)
%
% A function that allows user to choose a window of the channel data,
% then creates a new folder of gdats thusly truncated.
% xmin/xmax: window start/end, in milliseconds
% gdat_path: your original folder of gdats (e.g. ST03_bl19)
% new_path: this folder will be created for your newly windowed gdats
%
% this will be useful if two sessions (delineated by two flashing start sequences) are
% recorded into a single data tank by accident.
%
% Example use:
%  gdat_path = '/Volumes/kanile/wandell7/data/ECoG/ecog02/ecog/miniKM/ST03_bl19';
%  new_path = '/Volumes/kanile/wandell7/data/ECoG/ecog02/ecog/miniKM/tempdir';
%  gdat_samplerate = 3051.76;
%  analog_samplerate = 24414.1;
%  xmin = 1000;
%  xmax = 100000;
%  gdat_window(xmin,xmax,samplerate,analog_samplerate,gdat_path,new_path);
%
% jc 09/14/09
% 
% changed code to load and save multiple files for the analog channels as well.
% nw 09/21/09  

amin = round((xmin/1000)*analog_samplerate);
amax = round((xmax/1000)*analog_samplerate);
gmin = round((xmin/1000)*gdat_samplerate);
gmax = round((xmax/1000)*gdat_samplerate);

if exist(new_path,'dir')
    fprintf([new_path ' already exists. Operation failed.\n']);
else
    [pathstr,name] = fileparts(new_path);
    mkdir(pathstr,name);
    cd(gdat_path);
    
    %% analog channel
%     get names of channels
    d = dir('analog*.mat');
%     go to that directory
    cd(gdat_path);
%     load each channel data in turn from the struct d.name
    for i=1:length(d)
        load(d(i).name);
        varname = d(i).name(1:end-4); % remove .mat from name
        % analog_1 = analog_1(amin:amax);
%         select sample points of interest
        eval([varname '=' varname '(amin:amax);']);
% save in new location
        eval(['save ' new_path '/' varname '.mat ' varname ';']);
    end
    
    %% ecog channels
%     get names of channels
    d = dir('gdat*.mat');
    for n = 1:length(d)
        
        load(d(n).name);
        varname = d(n).name(1:end-4); % remove .mat from name
%         select time points of interest
        eval([varname '=' varname '(gmin:gmax);']);
%         save in new location
        eval(['save ' new_path '/' varname '.mat ' varname ';']);
    end
end





