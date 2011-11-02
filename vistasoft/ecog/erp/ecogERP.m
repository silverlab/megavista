function ecogERP(par,bef_win,aft_win,event_time,tag,elecs,poststimbase)
% ecogERP(par,bef_win,aft_win,event_time,tag,elecs,[poststimbase=0.1])
% Depends on lowHighFlit.m routine (?)
%
% written by mo (?) in 2009
%
% modified by jbh 2/14/2010
% fixed error- now loads CAR data instead of Filtered data - jc 05/26/10
%

% event_time is a vector of onsets (in seconds) or a cell array of such vectors
% tag is a string (name of the condition) or a cell array of strings
% event_time and tag should be index-aligned and the same length!
% this mod was made in order to avoid loading amplitude files redundantly
% -jc
%
% poststimbase can now be any value (in seconds), default is 100ms (0.1 s)
%


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
% else                  % took this out so that poststimbase can be a value (in seconds), rather than a flag
%     poststimbase = 0;
end

bef_point= floor(bef_win * par.ieegrate);
aft_point= ceil(aft_win * par.ieegrate);
Npoints= bef_point + aft_point+1; %reading Npoints data point

win_base= floor(poststimbase * par.ieegrate); %100 ms after the begining of stimuli is part of base line
% Changed to argument j.chen 07/23/10

%% Generating ERPs

for ci= elecs;
    fprintf(['\nCalculating ERP for ' par.block ' electrode ' num2str(ci) '\n']);
    
    load(sprintf('%s/CARiEEG%s_%.2d',par.CARData,par.block,ci));
    
    %     %% moving window around
    %     load(sprintf('%s/events_%s',globalVar.result_dir,block_name))
    %     gi=2; % category number
    
    %     bef_win= 0.1; % Window before events
    %     aft_win= 2; % Window after events
    %     tag= sprintf('%s',events.categories(gi).name);
    %     event_time= events.categories(gi).start;
    
    %     fprintf('%s\n\n',tag)
       
    
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
        condstruct(fi).elecs(ci).mean= mean(erp_tmp,1);
        condstruct(fi).elecs(ci).std= std(erp_tmp,0,1);
        condstruct(fi).elecs(ci).n= length(event_point);
        %         erp(fi).bef_point= bef_point;
        %         erp(fi).aft_point= aft_point;
    end
end

% fn= sprintf('%s',globalVar.result_dir);
% save(sprintf('%s/erp_%s_%s_%s.mat',fn,globalVar.project_name,tag,block_name),'erp');
% %return

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');
for cond = 1:length(tag)
    fprintf(['\nSaving ERP for condition ' tag{cond} '\n']);
    ERP.elecs = condstruct(cond).elecs;
    ERP.bef_point = bef_point;
    ERP.aft_point = aft_point;
    ERP.general.freq= par.freq;
    ERP.general.fs_comp= par.fs_comp;
    ERP.general.Npoints=Npoints;
    
    fn= sprintf('%s',par.Results);
    save(sprintf('%s/ERP_%s_%s_%s_%s.mat',fn,par.exptname,tag{cond},windurstr,par.block),'ERP');
end




% mean_erp= erp(fi).mean;
% std_erp= erp(fi).std;
%
% figure(1), %plot(mean_erp+std_erp/sqrt(22),'--r','LineWidth',2)
% hold on,plot(mean_erp,'b','LineWidth',4),
% %hold on,plot(mean_erp-std_erp/sqrt(22),'--g','LineWidth',2)
% set(gca,'XTick', linspace(bef_point,Npoints,5))
% set(gca,'XTickLabel',{'0', num2str(aft_win/4), num2str(aft_win/2), num2str(3*aft_win/4) num2str(aft_win)})
% set(gca,'FontSize',14)
% xlabel('Time (sec)','FontSize',14);
% ylabel('Voltage (AU)','FontSize',14);
% axis tight
% title(sprintf('%s %s chan %.3d',tag,block_name,ci),'FontSize',18);
% return
% fp= sprintf('%s/erp_%s_%s_%.3d.jpg',globalVar.print_dir,tag,block_name,ci);
% print('-f1','-djpeg',fp);