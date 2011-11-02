function ecogNormERSPmultblock(par,bef_win,aft_win,tag,elecs,surr_tag)
% Modified by j.chen jul 2010 from ecogNormERSP,
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
%   surr_tag is an optional arg that will load a specified surrogate data
%   set instead of the default tag

if ~exist('elecs','var') 
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

multname = [par.block(1:3) 'mult'];
  
windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');
fn= sprintf('%s',par.Results);
load(sprintf('%s/%s/ERSP_%s_%s_%s_%s.mat',fileparts(fn),multname,par.exptname,tag,windurstr,multname));
fprintf(['Calculating Zscore for ' tag '\n']);
if exist('surr_tag','var')
    load(sprintf('%s/%s/surrogate_%s_%s_%s_%s.mat',fileparts(fn),multname,par.exptname,surr_tag,windurstr,multname));
    fprintf(['Using surrogate data from ' surr_tag ' for ' tag '\n']);
else
    load(sprintf('%s/%s/surrogate_%s_%s_%s_%s.mat',fileparts(fn),multname,par.exptname,tag,windurstr,multname));
end

%% Normalizing by estimated mean and std of the population
Zscore= zeros(length(ERSP.general.freq),ERSP.general.Npoints,par.nchan); 

for ci= elecs
        
    % first calculate the mean ersp, weighted by ntrials in each block
    ersp = 0; ntrials = 0;
    for bi = 1:length(ERSP.elec(ci).block)
        ersp = ersp + ERSP.elec(ci).block(bi).power;
        ntrials = ntrials + ERSP.block(bi).Nevents;
    end
    ersp = ersp/ntrials;
    
    MN= surrogate.elecs(ci).MN;
    STD= surrogate.elecs(ci).STD;
    fprintf([num2str(ci) ' ']);
    Zscore(:,:,ci)= (ersp-MN)./STD;
end
fprintf('\n');

%% Saving
fn= sprintf('%s',par.Results);
if exist('surr_tag','var')
    save(sprintf('%s/%s/normERSP_%s_%s_%s_%s.mat',fileparts(fn),multname,par.exptname,tag,windurstr,multname),'Zscore','surr_tag');
else
    save(sprintf('%s/%s/normERSP_%s_%s_%s_%s.mat',fileparts(fn),multname,par.exptname,tag,windurstr,multname),'Zscore');
end
