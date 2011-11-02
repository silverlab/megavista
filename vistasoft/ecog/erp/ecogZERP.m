function ecogZERP(par,stdev,bef_win,aft_win,event_time,tag,elecs,poststimbase)
% ecogZERP(par,bef_win,aft_win,event_time,tag,elecs)
%
% Calculates the normalized ERP for a given block, based on the stdev of
% the entire timecourse EXCEPT the following periods: 
% a) before the first trial;
% b) between study and test, if AIN; 
% c) after end of last trial.
% This stdev is calculated separately by ecogStdev.m, which accepts
% start/end timepoints (from ecogBatch), and saved in the Results/block directory as:
% stdev_exptname_blockname.mat, varname= stdev
% jc 04/04/11
%
% modified from ecogERP
% written by mo (?) in 2009
% modified by jbh 2/14/2010
% fixed error- now loads CAR data instead of Filtered data - jc 05/26/10
%
% event_time is a vector of onsets (in seconds) or a cell array of such vectors
% tag is a string (name of the condition) or a cell array of strings
% event_time and tag should be index-aligned and the same length!
% this mod was made in order to avoid loading amplitude files redundantly
% -jc

% Update path info based on par.basepath
par = ecogPathUpdate(par);

%% handle different input specifications...
if ~exist('elecs','var')
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

if ~iscell(event_time)
    event_time = {event_time};
end
if ~iscell(tag)
    tag = {tag};
end

% By default, 100 ms after the begining of stimuli is part of base line
if ~exist('poststimbase','var')
    poststimbase = 0.1;
else
    poststimbase = 0;
end

bef_point= floor(bef_win * par.ieegrate);
aft_point= ceil(aft_win * par.ieegrate);
Npoints= bef_point + aft_point+1; %reading Npoints data point

win_base= floor(poststimbase * par.ieegrate); %100 ms after the begining of stimuli is part of base line
% Changed to argument j.chen 07/23/10

%% Generating ERPs

for ci= elecs;
    fprintf(['\nCalculating ZERP for ' par.block ' electrode ' num2str(ci) '\n']);
    load(sprintf('%s/CARiEEG%s_%.2d',par.CARData,par.block,ci));
    
    %% Averaging iERP segments
    for fi=1:length(tag)
        
        % event points
        event_point= floor(event_time{fi} * par.ieegrate);
        id= (event_point - bef_point);
        % jd= (event_point + bef_point);
        jd= (event_point + aft_point); % changed from above. this is supposed to prevent event_points being beyond recording time. j.chen 07/23/10
        event_point(id<0)=[];
        event_point(jd>par.chanlength)=[];
        
        
        signal = wave; %????
        erp_tmp= zeros(length(event_point),Npoints,'single');
        for eni=1:length(event_point);
            erp_tmp(eni,:)= signal(event_point(eni)-bef_point:event_point(eni)+aft_point);
            %removing mean of the base line
            erp_tmp(eni,:)= erp_tmp(eni,:) - mean(signal(event_point(eni)-bef_point:event_point(eni)+ win_base));
        end
        condstruct(fi).elecs(ci).mean = mean(erp_tmp,1) / stdev(ci).std;
        condstruct(fi).elecs(ci).stdz = std(erp_tmp,0,1) / stdev(ci).std;
        condstruct(fi).elecs(ci).std = stdev(ci).std;
        condstruct(fi).elecs(ci).n = length(event_point);

    end
end

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');
for cond = 1:length(tag)
    fprintf(['\nSaving ZERP for condition ' tag{cond} '\n']);
    ERP.elecs = condstruct(cond).elecs;
    ERP.bef_point = bef_point;
    ERP.aft_point = aft_point;
    ERP.general.freq= par.freq;
    ERP.general.fs_comp= par.fs_comp;
    ERP.general.Npoints=Npoints;
    
    fn= sprintf('%s',par.Results);
    save(sprintf('%s/ZERP_%s_%s_%s_%s.mat',fn,par.exptname,tag{cond},windurstr,par.block),'ERP');
end


