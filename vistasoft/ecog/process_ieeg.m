clear

%% INPUT, loading global variables
sbj_name= 'RM';
block_name= 'ST06_30';
project_name= 'MTloc';
load(sprintf('global_%s_%s_%s.mat',project_name,sbj_name,block_name));

%% Compressing data before referencing
%compressData(globalVar)

%% Filtering 60 Hz line noise
%noiseFiltData(globalVar)

%% re-referencing data to the common average reference CAR
%commonAvgRef(globalVar,'noiseFilt') % 'orig'

%% Electrodes of interest 
elecs =58;
%elecs= [21 22 26 27 36 44 51:59];

%% decomposing signal into Ampilitude and Phase for different frequencies
%dataDecompose(globalVar,elecs);
%return

%% finding events and categories 
%events= event_rest(globalVar);

%% moving window around
load(sprintf('%s/events_%s',globalVar.result_dir,block_name))
gi=1; % category number

bef_win= 0.1; % Window before events
aft_win= 2; % Window after events
tag= sprintf('%s',events.categories(gi).name);
event_time= events.categories(gi).start;

fprintf('%s\n\n',tag)

%% Generating ERSP
ERSP(globalVar,bef_win,aft_win,event_time,tag,elecs);

%% Generating iERP

%% Surrogate data for ERSP
surr_iter=500; % should be bigger than 2 iterations
MXnumEvent= max(events.categories(gi).numEvents);
surrogate_ersp(globalVar,bef_win,aft_win,MXnumEvent,tag,elecs,surr_iter);

%% Normalizing ERSP with respect to surrogate data
norm_ersp(globalVar,tag,elecs);
   
%% ploting normalized ERSP    
%plot_erp(globalVar,bef_win,aft_win,elecs,tag,2);
plot_erp2(globalVar,bef_win,aft_win,elecs,tag)
    


