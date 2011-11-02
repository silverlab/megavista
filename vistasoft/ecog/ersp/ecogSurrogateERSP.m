function ecogSurrogateERSP(par,bef_win,aft_win,tag,MXnumEvents,surr_iter,elecs)

% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Last revision date SEP,2009
% Modified j.chen dec 2009

if ~exist('elecs','var') 
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

if ~iscell(tag)
    tag = {tag};
end

bef_point= floor(bef_win * par.fs_comp);
aft_point= ceil(aft_win * par.fs_comp);
Npoints= bef_point + aft_point+1; %reading Npoints data point

for ci= elecs
    fprintf(['\nCalculating surrogate data for ' par.block ' electrode ' num2str(ci) ', ' num2str(find(elecs==ci)) ' of ' num2str(length(elecs))]);
    % Reading amplitude of channel ci
    load(sprintf('%s/amplitude_%s_%.3d',par.SpecData,par.block,ci)) % 'amplitude'
    amplitude= amplitude.^2; % Power
    mean_power= mean(amplitude,2);
    saved_mean_power = mean_power;
    mean_power= mean_power*ones(1,size(amplitude,2));
    amplitude= amplitude./mean_power; % normalized by mean of power 4 each par.freq
    clear mean_power

    %% all points in our data set
    ind= 1:size(amplitude,2);
    ind(1:bef_point)=[];
    ind(end-aft_point+1:end)=[];
    
    % We do not want to include the epileptic signal in our surrogate
    % If no ictal events are defined, use the whole channel
    if ~isempty(intersect(ci, par.epichan)) 
        if ~isnan(par.ictal{ci}(1))
            ictal_event= par.ictal{ci};
            all=[];
            for ii=1:length(ictal_event)
                all=[all floor(ictal_event(1,ii)*par.fs_comp)-aft_point+1 : ceil(ictal_event(2,ii)*par.fs_comp+bef_point)];
            end
            ind(all)=[];
        end
    end
    
    for cond=1:length(tag)
        fprintf(['\nCondition ' tag{cond} ', iteration: ']);
        condstruct(cond).surrogate.elecs(ci).meanPower= saved_mean_power;

        surr_sum= zeros(size(amplitude,1),Npoints,'single');
        surr_sqr= zeros(size(amplitude,1),Npoints,'single');
        for ii=1:surr_iter
            % get MXnumEvent number of random time points and create ERPs around
            % those from your original amplitude time series
            p_event= randsample(ind,MXnumEvents(cond),true); % Choosing random events from eligible indices

            ERP= zeros(size(amplitude,1),Npoints,'single');
            erp_tmp= zeros(size(amplitude,1),Npoints,length(p_event),'single');
            for eni=1:length(p_event);
                erp_tmp(:,:,eni)= amplitude(:,p_event(eni)-bef_point:p_event(eni)+aft_point);
            end
            ERP= mean(erp_tmp,3);

            surr_sum= surr_sum + ERP;
            surr_sqr= surr_sqr + ERP.^2;
            if rem(ii,250)==0
                fprintf([num2str(ii) ' ']);
            end
        end

        condstruct(cond).surrogate.elecs(ci).MN.value= surr_sum./surr_iter;
        variance= (surr_sqr - (surr_sum).^2./surr_iter) ./ (surr_iter-1);
        if isreal(sqrt(variance))
            condstruct(cond).surrogate.elecs(ci).STD.value= sqrt(variance); % standard deviation
        else
            error('surr_iter is not big enough')
        end
    end
    
    clear amplitude
    fprintf('\n');
end

%% Saving data

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

for cond=1:length(tag)
    fprintf(['\nSaving surrogate data for condition ' tag{cond} ' window duration ' windurstr '\n']);
    surrogate = condstruct(cond).surrogate;
    surrogate.general.freq = par.freq;
    surrogate.general.fs_comp = par.fs_comp;
    fn= sprintf('%s',par.Results);
    save(sprintf('%s/surrogate_%s_%s_%s_%s.mat',fn,par.exptname,tag{cond},windurstr,par.block),'surrogate');
end

