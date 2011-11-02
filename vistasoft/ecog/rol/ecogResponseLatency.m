function [peakTimes,halfPeakTimes,peakValues,timeToPassThresh,noRespTrials] = ecogResponseLatency(par,ci,freqBand,timeWindow,eventtimes,condnums,normFlag)
% This function should find the response latency for a particular
% electrode, using the power in a particular frequency band.  This code is
% simpler than Mo's ROL code.  It should be possible to add other ways of
% calculating the response onset latency.  Right now, we just find the peak
% of the power in the selected frequency band.  We set the baseline of each
% trial as the time before trial onset.
%
%  [peakTimes,halfPeakTimes,peakValues,timeToPassThresh,noRespTrials] =
%  ecogResponseLatency(par,ci,freqBand,timeWindow,eventtimes,condnums,[normFlag=0])
%
% INPUTS:
%
% par is a struct containing several parameters that we need about this
% recording block
%
% freqBand is a vector of 2 values, which are the frequency bands for which
% we find the power, on which the response latency is based
%
% timeWindow is a vector of 2 values, both positive.  The first index is
% the time before trial onset to include (i.e the baseline time), and
% timeWindow(2) is how long after the trial onset to include.
%
% eventtimes is a vector of onset times for each condition
%
% condnum is a vector of conditions for which to calculate onset latencies
%
% normFlag, if 1, normalizes the amplitude of every trial to its peak (i.e.
% peak amplitude = 1)
%
% OUTPUTS:
%
% peakTimes is a matrix length(condnums) x number of trials, giving the peak of
% the response for each responsive trial for each condition
%
% halfPeakTimes is same as peakTimes except it is the time (closest to the
% peak before the peak) at which the signal reaches half the peak
%
% peakValues is same size as peakTimes, and it gives the values (how many times the baseline) at the peak
%
% noRespTrials is a cell array of trials not passing threshold (condnums x trials)
%

befwin = timeWindow(1);
aftwin = timeWindow(2);

if ~exist('normFlag','var'), normFlag = 0; end

%% Decompose into the frequency band that you want
% locut = [1 4 8 30 80 30];
% hicut = [4 7 25 80 180 180];
locut = freqBand(1);
hicut = freqBand(2);
ecogDataDecomposeBand(par,ci,locut,hicut);

%% Get power across the whole recording block
% get input from process_ROL.m
% feed input to respfunc2.m
% dependency: respfunc2.m
fs_comp= par.fs_comp;
% Reading amplitude of channel ci
load(sprintf('%s/band_%s_%.3d',par.SpecData,par.block,ci));
amplitude= band.amplitude;
power_tmp= double(amplitude(1,:).^2); % Signal Power  % note that this only works if you have only decomposed the signal into 1 frequency band, or if you want the first frequency band from several
%power_tmp= power_tmp/mean(power_tmp); % relative Power


for condnum = condnums
    clear event_time mn_tmp peak tpeak peakVal peakSamp tHalfMax timeOverThresh allAboveThreshInds

    %% Get right event times for this condition
    event_time= eventtimes{condnum};
    event_point= floor(event_time * fs_comp); % I think this is right, but it depends on having done compression elsewhere
    event_dur= ones(size(event_time));  % let's just call it 1 second for now.  I think this only gets used as a max possible ROL (in ecogRespfunc2)


    %% Set up information for trial lengths

    aftwin_mx= max(event_dur);
    aftwin= event_dur;
    aft_point= ceil(aftwin * fs_comp);
    bef_point= floor(befwin * fs_comp);
    aft_point_mx= ceil(aftwin_mx * fs_comp);
    Npoints= bef_point + aft_point_mx+1; %reading Npoints data point
    time= linspace(-befwin,aftwin_mx,Npoints);

    id= event_point - bef_point;
    event_point(id<0)=[];
    jd= (event_point + bef_point);
    event_point(jd>par.chanlength)=[];

    %% Smooth with Gaussian Window (?) and baselining within each trial
    % event related signal, smoothed with a Gaussian window
 %   winSize= 150;% 50 points=100 msec= 3 low gamma cycles; at 80Hz, 1 cycle = 12ms = ~6 time points  %150
%    changing from 150 to 100 and to 50 increases ROL but within std so it is OK
  %  gusWin= gausswin(winSize)/sum(gausswin(winSize));

    mn_tmp= NaN*ones(length(event_point),Npoints);
    numTrials = length(event_point);

    
    for eni=1:numTrials;
        mn_tmp(eni,1:(bef_point+aft_point(eni)+1))= power_tmp(event_point(eni)-bef_point:event_point(eni)+aft_point(eni));
        bsln(eni) = mean(mn_tmp(eni,1:bef_point)); % take the time before trial onset as baseline

%             % Convolution with Gaussian window (blurring)
%             mn_tmp(eni,:)= convn(mn_tmp(eni,:),gusWin','same');
%             mn_tmp(eni,1:round(winSize/2))= NaN; % because of convolution
%             mn_tmp(eni,end-round(winSize/2):end)= NaN; % because of convolution

        % Normalize to baseline
        mn_tmp(eni,:) = mn_tmp(eni,:)./bsln(eni);  
        %mn_tmp(eni,:) = mn_tmp(eni,:)-bsln(eni);
        
    end
    
    if normFlag  % normalize to peak power in each trial
        peakPowers = max(mn_tmp');
        for trialNum = 1:numTrials
            mn_tmp(trialNum,:) = mn_tmp(trialNum,:)./peakPowers(trialNum);
        end
    end


    % Plot the power for each trial (or the mean/median trace)
    %figure; plot(time,median(mn_tmp))
    %figure; plot(time,mean(mn_tmp))
    
    % % Uncomment here to plot individual trial power
    %figure,plot(time,mn_tmp,'-o','LineWidth',2) %***********************
    %xlim([-befwin aftwin_mx]);set(gca,'FontSize',16)
    %if normFlag, ylim([0.05 1.05]); end
    %ylabel('Relative Power'),xlabel('Time (sec)')
    
    %line([-.2 5],[1 1],'Color','k','LineWidth',1)
    %line([-.2 5],[2.14 2.14],'Color','k','LineWidth',1)
    %line([0 0],[0 6],'Color','k','LineWidth',2)
    %line([5 5],[0 6],'Color','k','LineWidth',2)

    %% Find the time of the peak response for each trial within this block for
    %% this electrode, for this condition.  This should be done for multiple
    %% blocks and concatenated within that condition
    % restrict search space to 30 to 600ms after trial onset
    pwrPerc = mn_tmp(:,time>0.03 & time<0.6); %*******  % restrict search space to a specific portion of time after trial onset (all trials)
    maxVals = max(pwrPerc,[],2);  % find maximum within that search window

    thresh = 10; % threshold for counting the peak in the mean response time; in STDs of baseline period (before trial onset)
    %if normFlag, curThresh = 0.20; end  % some percentage of max response in trial, like 20% of max
    
    % Get an individual threshold for each trial based on STD
    baselineVals = mn_tmp(:,time<0);  % all values before trial onset
    baseSTDs = squeeze(std(baselineVals'));

    noResp = [];
    for tri = 1:length(maxVals)
        if ~normFlag  % if you haven't normalized trials, then convert to STDs for each trial
            curThresh = thresh*baseSTDs(tri)+1;  % thresh is now number of standard deviations (+1 because that is the mean of the baseline)
        else
            curThresh = thresh*baseSTDs(tri)+mean(baselineVals(tri,:));  % number of STDs ABOVE the baseline
        end
        
        if maxVals(tri)<curThresh  % peak does not pass STD threshold
            maxVals(tri)=NaN;
            noResp = [noResp tri];
            tpeak(tri) = NaN;
            peakVal(tri) = NaN;
            tHalfMax(tri) = NaN;
            timeOverThresh(tri) = NaN;
            
        else
            peakSamp(tri) = find(mn_tmp(tri,:)==maxVals(tri));  % find peak point in samples (relative to trial onset)
            tpeak(tri) = time(peakSamp(tri));  % convert to time
            peakVal(tri) = maxVals(tri);  % also save out the actual value of the peak
            
            % Get time value at half-max
            halfPeak = peakVal(tri)/2;
            largerValInds = find(mn_tmp(tri,:)>halfPeak);
            smallerValInds = find(mn_tmp(tri,:)<=halfPeak);
            contenders = intersect(largerValInds,smallerValInds+1);  % look for indices where you go from smaller than halfPeak to larger than halfPeak
            contenders = contenders(find(contenders<peakSamp(tri))); % limit to those that come before our peak in time
            tHalfMax(tri) = time(contenders(end));  % use the last value of the set, which is the one closest to the peak that comes before the peak
            
            % Get first time at which we pass threshold

            allAboveThreshInds = find(mn_tmp(tri,:)>curThresh);
            aboveThreshTimes = time(allAboveThreshInds);  % convert to time (in seconds)
            aboveThreshTimes = aboveThreshTimes(aboveThreshTimes>0.03 & aboveThreshTimes<0.6); % don't allow before 30 millisecond or after 600ms response
            if ~isempty(aboveThreshTimes)
                timeOverThresh(tri) = aboveThreshTimes(1); % take the first time we pass threshold after 30 milliseconds
            else
                timeOverThresh(tri) = NaN;  % electrode too noisy or no response
            end
            
        end
    end

    underThreshCount = length(noResp);

    noRespTrials{condnum,:} = noResp;
    peakTimes{condnum,:} = tpeak;
    halfPeakTimes{condnum,:} = tHalfMax;
    peakValues{condnum,:} = peakVal;
    timeToPassThresh{condnum,:} = timeOverThresh;
    
    % Output
    fprintf('ELECTRODE %d, CONDITION %d\n',ci,condnum);
    fprintf('Number of trials not passing threshold of %0.1f: %d of %d\n',thresh,underThreshCount,length(maxVals));
    fprintf('Median time to peak: %0.3f seconds\n',median(tpeak(~isnan(tpeak))));
    fprintf('Mean time to peak: %0.3f seconds\n',nanmean(tpeak));
    fprintf('STD: %0.3f seconds\n',nanstd(tpeak));
    fprintf('\n');
    


end

return












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MO's ROL code

thr= 5; %1.5; %1.5;%20%50%70% increase in signal

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
%% Plotting

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

    xlim([-.2 1.2]);set(gca,'FontSize',16)
    ylabel('Trials'),xlabel('Time (sec)')
    set(gca,'ytick',[])
    line([0 0],[0 35*2],'Color','k','LineWidth',2)
    line([5 5],[0 35*2],'Color','k','LineWidth',2)
end

