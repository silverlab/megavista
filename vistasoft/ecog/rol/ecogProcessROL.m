clear

% get input from process_ROL.m
% feed input to respfunc2.m 
% dependency: respfunc2.m

block_name= 'ST07-07'; %'ANP066';%%'AC0210_05';%'ST06_43';%;%'AC0210_05';%'KB0510_01';
sbj_name= 'CMM';
project_name= 'rest';
load(sprintf('global_%s_%s_%s.mat',project_name,sbj_name,block_name));

fs_comp= globalVar.fs_comp;

%% Electrodes of interest
ci= 51;

%% Event points
categNum= 7;

dir= sprintf('/users/MO/Codes/rest/%s/%s',sbj_name,block_name);
load(sprintf('%s/events_%s_%s.mat',dir,sbj_name,block_name));%CMM only
%load(sprintf('%s/events_%s.mat',dir,block_name));

event_time= events.categories(categNum).start;
event_point= floor(event_time * fs_comp);
event_dur= events.categories(categNum).duration;

%% windows (epoch length)
bef_win= 0.4;
aft_win_mx= max(event_dur)+0.4;
aft_win= event_dur+0.4;
aft_point= ceil(aft_win * fs_comp);
bef_point= floor(bef_win * fs_comp);
aft_point_mx= ceil(aft_win_mx * fs_comp);
Npoints= bef_point + aft_point_mx+1; %reading Npoints data point
time= linspace(-bef_win,aft_win_mx,Npoints);

id= event_point - bef_point;
event_point(id<0)=[];
jd= (event_point + bef_point);
event_point(jd>globalVar.chanLength)=[];

% Reading amplitude of channel ci
load(sprintf('%s/band_%s_%.3d',globalVar.Spec_dir,block_name,ci));
amplitude= band.amplitude;
power_tmp= double(amplitude(7,:).^2); % Signal Power
power_tmp= power_tmp/mean(power_tmp); % relative Power

% event realted signal
winSize= 150;% 50 points=100 msec= 3 low gamma cycles
%changing from 150 to 100 and to 50 increases ROL but within std so it is OK
gusWin= gausswin(winSize)/sum(gausswin(winSize));
mn_tmp= NaN*ones(length(event_point),Npoints);
for eni=1:length(event_point);
    mn_tmp(eni,1:(bef_point+aft_point(eni)+1))= power_tmp(event_point(eni)-bef_point:event_point(eni)+aft_point(eni));
    mn_tmp(eni,:)= convn(mn_tmp(eni,:),gusWin','same');
    mn_tmp(eni,1:round(winSize/2))= NaN; % because of convolution
    mn_tmp(eni,end-round(winSize/2):end)= NaN; % because of convolution
end

if 1==1
    figure,plot(time,mn_tmp,'LineWidth',2)
    xlim([-.2 5.2]);set(gca,'FontSize',16)
    ylabel('Relative Power'),xlabel('Time (sec)')
    line([-.2 5],[1 1],'Color','k','LineWidth',1)
    line([-.2 5],[2.14 2.14],'Color','k','LineWidth',1)
    line([0 0],[0 6],'Color','k','LineWidth',2)
    line([5 5],[0 6],'Color','k','LineWidth',2)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RESPONSE Time

thr= 1.5;%20%50%70% increase in signal

[n x]= hist(power_tmp(power_tmp<5),20);
%figure,semilogy(x,n,'b'),%% Exponential distribution
%hold on, line([1.2 1.2],[10^2 10^6],'Color','k','LineWidth',1)
%cdf_thr= sum(power_tmp>thr)/length(power_tmp);

[rsp_onset,rsp_val,rt_abv,rv_abv,ri_abv]= ecogRespfunc2(mn_tmp,time,event_dur,thr);

fprintf('\n%d trials not responding out of %d:%5.2f percent\n',sum(isnan(rsp_onset)),length(rsp_onset),sum(isnan(rsp_onset))/length(rsp_onset))
mdn= median(rsp_onset(~isnan(rsp_onset)));
mn_rsp= mean(rsp_onset(~isnan(rsp_onset)));
sd= std(rsp_onset(~isnan(rsp_onset)));
semdn= 1.253* ( sd/sqrt(length(rsp_onset)-sum(isnan(rsp_onset)))); %standard error of median
fprintf('\nResponse onset latency:\n Median:%4.3f+-%4.3f\n mean:%4.3f\n std:%4.3f \n\n',mdn,semdn,mn_rsp ,sd);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 1==1
%% ROL of Random events 
ind_shf= 1:size(band.amplitude,2);
ind_shf(1:bef_point)=[];
ind_shf(end-aft_point_mx+1:end)=[];

fprintf('\nfinding ROL of random trails; iteration:\n')
md=[];
rsp_shf= [];
for iter=1:50
    if rem(iter,5)==0,fprintf('%d out of %d\n',iter,50),end
    clear event_point
    event_point= randsample(ind_shf,length(event_time),true); % Choosing random events from eligible indices
    % over-writting event_point but keeping the original duration

    mn_tmp_shf= NaN*ones(length(event_point),Npoints);
    for eni=1:length(event_point);
        mn_tmp_shf(eni,1:(bef_point+aft_point(eni)+1))= power_tmp(event_point(eni)-bef_point:event_point(eni)+aft_point(eni));
        mn_tmp_shf(eni,:)= convn(mn_tmp_shf(eni,:),gusWin','same');
        mn_tmp_shf(eni,1:round(winSize/2))= NaN; % because of convolution
        mn_tmp_shf(eni,end-round(winSize/2):end)= NaN; % because of convolution
    end
    
    [rsp_onset_shf,rsp_val_shf,rt_abv_shf,rv_abv_shf,ri_abv_shf]= ecogRespfunc2(mn_tmp_shf,time,event_dur,thr);
    md= [md median(rsp_onset_shf(~isnan(rsp_onset_shf)))];
    rsp_shf= [rsp_shf;rsp_onset_shf];
end

mdn_shf= mean(md);
sem_mdn_shf= std(md)/sqrt(length(md));
fprintf('\nRandom ROL:\n Median:%4.3f+-%4.3f\n\n',mdn_shf,sem_mdn_shf);

if 1==1
    tmp_rsp= rsp_onset(~isnan(rsp_onset));
    tmp_rsp_shf= rsp_shf(~isnan(rsp_shf));
    figure,plot(sort(tmp_rsp),100*[1:length(tmp_rsp)]/length(tmp_rsp),'r','MarkerSize',5,'LineWidth',2)
    hold on,plot(sort(tmp_rsp_shf),100*[1:length(tmp_rsp_shf)]/length(tmp_rsp_shf),'g','MarkerSize',5,'LineWidth',2)
    xlim([-0.2 5]), ylim([0 105])
    set(gca,'FontSize',12)
    xlabel('Response Onset Latency(sec)'),ylabel('Sorted trials (%)')
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% saving 
% save(sprintf('%s/rspOnset_%3.1f_%s_%s_%.2d.mat',dir,thr,block_name,events.categories(categNum).name,ci),'rsp_onset','rsp_shf','mdn_shf','sem_mdn_shf');
% return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Ploting

if 1==1
    %% plotting all trials
    [rt_sort rt_ind]= sort(rt_abv);
    figure,
    shf=0;
    for trl= rt_ind(1:end)
        shf= 2+ shf;
        hold on, plot(time,mn_tmp(trl,:)+shf,'LineWidth',2)
        %line([-.2 5.2],[bsln+shf bsln+shf],'Color','r','LineWidth',1)
        hold on, plot(rt_abv(trl),rv_abv(trl)+shf,'go','MarkerSize',5,'LineWidth',5) %Threshold
        
        hold on, plot(rsp_onset(trl),rsp_val(trl)+shf,'ro','MarkerSize',5,'LineWidth',5)%Response Onset
        
        if ~isnan(ri_abv(trl))
            wt=50;
            x= time(ri_abv(trl)-wt:ri_abv(trl)+wt);
            y= mn_tmp(trl,ri_abv(trl)-wt:ri_abv(trl)+wt);
            P= polyfit(x,y,1);
            y2= polyval(P,x);
            hold on, plot(x,y2+shf,'r')
        end
        %hold on, plot(xt(trl),bsln+shf,'go','MarkerSize',5,'LineWidth',5)
        
    end
    
    xlim([-.2 5.2]);set(gca,'FontSize',16)
    ylabel('Trials'),xlabel('Time (sec)')
    set(gca,'ytick',[])
    line([-.2 5],[1 1],'Color','k','LineWidth',2)
    line([0 0],[0 48*2],'Color','k','LineWidth',2)
    line([5 5],[0 48*2],'Color','k','LineWidth',2)
end

if 1==1
    [rt_sort rt_ind]= sort(rt_abv);
    figure,
    imagesc(mn_tmp(rt_ind,:)-1,[-1 1]), axis xy
    
    tmp_rsp= sort(rsp_onset(~isnan(rsp_onset)));
    for ii=1:length(tmp_rsp)
        mi= find(time<tmp_rsp(ii));
        t_ind(ii)= mi(end);
    end
    hold on,plot(t_ind,[1:length(tmp_rsp)],'k','LineWidth',3)
    ji= find(time<0);
    %jj= find(time< median(event_dur));
    line([ji(end) ji(end)],[0 48],'Color','k','LineWidth',2)
    %line([jj(end) jj(end)],[0 48],'Color','k','LineWidth',2)
    ylabel('Sorted trials according to ROL','FontSize',14),xlabel('Time (sec)','FontSize',14)
    set(gca,'XTick',[ji(end) ji(end)+round(fs_comp) ji(end)+round(2*fs_comp) ji(end)+round(3*fs_comp) ji(end)+round(4*fs_comp) ji(end)+round(5*fs_comp) ])
    set(gca,'XTickLabel',{'0','1','2','3','4' '5'})
    set(gca,'FontSize',14)
    title(sprintf('%s %s %s chan:%.2d',sbj_name,block_name,events.categories(categNum).name,ci))
    
    %fp= sprintf('%s/figure/rspOnset_%s_%s_%.2d.jpeg',dir,block_name,events.categories(categNum).name,ci);%AC
    %fp= sprintf('%s/figures/rspOnset_%s_%s_%.2d.jpeg',dir,block_name,events.categories(categNum).name,ci);
    %print('-f1','-djpeg',fp);
end

if 1==1
    %% plotting all trials not sorted
    figure,
    shf=0;
    for trl=1:size(mn_tmp,1)
        shf= 2+ shf;
        hold on, plot(time,mn_tmp(trl,:)+shf,'LineWidth',2)
        hold on, plot(rsp_onset(trl),rsp_val(trl)+shf,'ro','MarkerSize',5,'LineWidth',5)%Response Onset
    end
    
    xlim([-.2 5.2]);set(gca,'FontSize',16)
    ylabel('Trials'),xlabel('Time (sec)')
    set(gca,'ytick',[])
    line([0 0],[0 35*2],'Color','k','LineWidth',2)
    line([5 5],[0 35*2],'Color','k','LineWidth',2)
end

