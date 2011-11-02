function ecogNormERSP(par,bef_win,aft_win,tag,elecs,surr_tag)
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Last revision date SEP,2009
% Modified j.chen jan 2010
%   surr_tag is an optional arg that will load a specified surrogate data
%   set instead of the default tag

if ~exist('elecs','var') 
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');
fn= sprintf('%s',par.Results);
load(sprintf('%s/ERSP_%s_%s_%s_%s.mat',fn,par.exptname,tag,windurstr,par.block));
if exist('surr_tag','var')
    load(sprintf('%s/surrogate_%s_%s_%s_%s.mat',fn,par.exptname,surr_tag,windurstr,par.block));
    fprintf(['Using surrogate data from ' surr_tag ' for ' tag '\n']);
else
    load(sprintf('%s/surrogate_%s_%s_%s_%s.mat',fn,par.exptname,tag,windurstr,par.block));
end

%% Normalizing by estimated mean and std of the population
Zscore= zeros(length(ERSP.general.freq),ERSP.general.Npoints,par.nchan); 

for ci= elecs
    ersp= ERSP.elecs(ci).value;
    MN= surrogate.elecs(ci).MN.value;
    STD= surrogate.elecs(ci).STD.value;
    fprintf([num2str(ci) ' ']);
    Zscore(:,:,ci)= (ersp-MN)./STD;
end
fprintf('\n');

% %% Saving
% fn= sprintf('%s',par.Results);
% if exist('surr_tag','var')
%     save(sprintf('%s/%s/normERSP_%s_%s_%s_%s.mat',fn,[bprefix 'cat'],par.exptname,tag,windurstr,par.block),'Zscore','surr_tag');
% else
%     save(sprintf('%s/%s/normERSP_%s_%s_%s_%s.mat',fn,[bprefix 'cat'],par.exptname,tag,windurstr,par.block),'Zscore');
% end

%% Saving
fn= sprintf('%s',par.Results);
if exist('surr_tag','var')
    save(sprintf('%s/normERSP_%s_%s_%s_%s.mat',fn,par.exptname,tag,windurstr,par.block),'Zscore','surr_tag');
else
    save(sprintf('%s/normERSP_%s_%s_%s_%s.mat',fn,par.exptname,tag,windurstr,par.block),'Zscore');
end
