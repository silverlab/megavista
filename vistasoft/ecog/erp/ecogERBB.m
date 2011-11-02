function ecogERBB(par,bef_win,aft_win,event_time,tag,elecs,poststimbase,minfreq,maxfreq)
% jc apr 2011

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

bef_point= floor(bef_win * par.fs_comp);
aft_point= ceil(aft_win * par.fs_comp);
Npoints= bef_point + aft_point+1; %reading Npoints data point

win_base= floor(poststimbase * par.fs_comp); % poststimbase ms after the begining of stimuli is part of baseline

%% Generating ERBBs

for ci= elecs;
    fprintf(['\nCalculating ERBB for ' par.block ' electrode ' num2str(ci) '\n']);
    
%     load(sprintf('%s/bbiEEG_%s_%.3d',par.BBData,par.block,ci));
    load(sprintf('%s/bbiEEG_%s_%.3d_%.3d_%.3d',par.BBData,par.block,minfreq,maxfreq,ci));
    
    %% Averaging ERBB segments
    for fi=1:length(tag)
        
        % event points
        event_point= floor(event_time{fi} * par.fs_comp);
        id= (event_point - bef_point);
        jd= (event_point + aft_point); 
        event_point(id<0)=[];
        event_point(jd>par.chanlength)=[];
                
        signal_power = bb.^2; 
        mean_power= mean(signal_power,2);
        amplitude= signal_power./(mean_power*ones(1,size(signal_power,2))); % normalized by mean of power
 
        erbb_tmp= zeros(length(event_point),Npoints,'single');
        for eni=1:length(event_point);
            erbb_tmp(eni,:)= amplitude(event_point(eni)-bef_point:event_point(eni)+aft_point);
            %removing mean of the base line
            erbb_tmp(eni,:)= erbb_tmp(eni,:) - mean(amplitude(event_point(eni)-bef_point:event_point(eni)+ win_base));
        end
        condstruct(fi).elecs(ci).mean= mean(erbb_tmp,1);
        condstruct(fi).elecs(ci).std= std(erbb_tmp,0,1);
        condstruct(fi).elecs(ci).n= length(event_point);
    end
end

% fn= sprintf('%s',globalVar.result_dir);
% save(sprintf('%s/erbb_%s_%s_%s.mat',fn,globalVar.project_name,tag,block_name),'erbb');
% %return

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');
for cond = 1:length(tag)
    fprintf(['\nSaving ERBB for condition ' tag{cond} '\n']);
    ERBB.elecs = condstruct(cond).elecs;
    ERBB.bef_point = bef_point;
    ERBB.aft_point = aft_point;
    ERBB.general.freq= par.freq;
    ERBB.general.fs_comp= par.fs_comp;
    ERBB.general.Npoints=Npoints;
    
    fn= sprintf('%s',par.Results);
    save(sprintf('%s/ERBB_%s_%s_%s_%s_%.3d_%.3d.mat',fn,par.exptname,tag{cond},windurstr,par.block,minfreq,maxfreq),'ERBB');
end

