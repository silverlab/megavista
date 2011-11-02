function [rsp_onset,rsp_val,rt_abv,rv_abv,ri_abv]= ecogRespfunc2(mn_tmp,time,event_dur,thr)

% calculate the reponse onset latency for the activation
% input comes from respLatency.m script
% rsp_onset: time of the onset 
% rsp_val: GP of the onset
% rt_abv: when the GP pass exceeds the threshold in second unit
% rv_abv: GP of the rt_abv 
% ri_abv: when the GP pass exceeds the threshold in point unit

tmp= mn_tmp(:,time>=-0.2 & time<=0);% baseline
bsln= mean(tmp(:)); % baseline

rt_abv= NaN* ones(1,size(mn_tmp,1));
rv_abv= NaN* ones(1,size(mn_tmp,1));
ri_abv= NaN* ones(1,size(mn_tmp,1));
for trl=1:size(mn_tmp,1)
    trc= mn_tmp(trl,:); % trace
    ind= 1:length(time);
    
    %% the time of the increased response
    abv= time(trc>thr);
    if (length(abv)~=0)
        %abvInd= ind(trc>thr);
        abvInd= ind(trc>thr & time>0.1 & time<event_dur(trl)); %SHOULD BE MODIFIED 
        abvDf= zeros(1,length(time));
        abvDf(abvInd)=1;
        abvDf = [0 diff(abvDf)];
        abvT= time(abvDf==1);
        abvI= ind(abvDf==1);
        for ii=1:length(abvI)
            if sum(trc(abvI(ii):abvI(ii)+46)> thr)>46 %100ms ~3 cycles 30Hz
                rt_abv(trl)= time(abvI(ii));
                rv_abv(trl)= trc(abvI(ii));
                ri_abv(trl)= abvI(ii);
                break
            end
        end
    end
end

%[rt_sort rt_ind]= sort(rt_abv);
%median(rt_sort(~isnan(rt_sort)))
%mean(rt_sort(~isnan(rt_sort)))
%std(rt_sort(~isnan(rt_sort)))
%fprintf('\nResponse threshold:\n median: %4.3f\n\n',median(rt_sort(~isnan(rt_sort))));

rsp_onset= NaN* ones(1,size(mn_tmp,1));
rsp_val= NaN* ones(1,size(mn_tmp,1));
for trl= 1:size(mn_tmp,1)
    if ~isnan(ri_abv(trl))
        %wt=50;
        %x= time(ri_abv(trl)-wt:ri_abv(trl)+wt);
        %y= mn_tmp(trl,ri_abv(trl)-wt:ri_abv(trl)+wt);
        %P(trl,:)= polyfit(x,y,1);
        
        %xt(trl)= (bsln-P(trl,2))/P(trl,1);
        %itmp= find(time<xt(trl));
        %xind(trl)= itmp(end);
        %w_ind= xind(trl):ri_abv(trl);
        %w_time= time(xind(trl):ri_abv(trl));
        
        w_ind= (ri_abv(trl)-99):ri_abv(trl)+50; %200ms before to 100ms after
        w_ind(w_ind<1)=[];
        w_time= time(w_ind);
        
        t_tmp= buffer(w_time,45,40,'nodelay');
        
        sig_tmp= mn_tmp(trl,w_ind);
        sig_tmp= buffer(sig_tmp,45,40,'nodelay');
        i_tmp= find(sig_tmp(:,end)==0);
        sig_tmp(i_tmp,end)= NaN;
        
        slope=[];mse=[];
        for ii=1:size(sig_tmp,2)
            Ps= polyfit(t_tmp(:,ii),sig_tmp(:,ii),1);
            y2= polyval(Ps,t_tmp(:,ii));
            slope(ii)= Ps(1);
            mse(ii)= sum((y2-sig_tmp(:,ii)).^2);
        end
        
        if all(~isnan(slope))
            [s_tmp iA]= sort(slope,'descend');
            [e_tmp iB]= sort(mse,'ascend');
            i_tmp= find( mse(iA(1:5))== min(mse(iA(1:5))) );
            
            rsp_onset(trl)= t_tmp(1,iA(i_tmp));
            rsp_val(trl)= mn_tmp(trl,find(time==rsp_onset(trl)));
        end
    end   
end

