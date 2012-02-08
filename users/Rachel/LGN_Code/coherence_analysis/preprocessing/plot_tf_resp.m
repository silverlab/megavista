function h = plot_tf_resp(ds)

% plots the time-frequency response, spike arrival times and average firing rate (PSTH) for
% the data structure ds.   Returns a handle to the figure.

before_stim = 2000;                     % Time before stimulus in ms
total_duration = 6000;                  % Total display in ms.
stim_length = ds.stim.stimLength*1000.0; % Stimulus length in ms.
f_low = 500;
f_high = 8000;

% Get the number of trials
ntrials = length(ds.resp.rawSpikeTimes);
if ( ntrials > 50 ) 
	nplot=50;
else
	nplot = ntrials;
end

% Get the figure ready
h=figure;
set(h,'PaperPosition',[0.25 2.5 3.75 8]); % This is for hard copy
set(h,'Position', [50 50 1000 500]);

% Plot the time-frequency representation    
subplot(3,1,1);    

plot_tfrep(ds.stim.tfrep);
v_axis = axis;
after_stim = total_duration - before_stim - stim_length;
v_axis(1) = -before_stim/1000.0;
v_axis(2) = (stim_length + after_stim)/1000.0;
v_axis(3)=f_low; 
v_axis(4)=f_high;
axis(v_axis);                                


% plot spike array and calculate average
ntimebins = before_stim + stim_length + after_stim; % Number of time bins in ms
psth = zeros(1, ntimebins);
t=1:ntimebins;
t = (t-before_stim)./1000.0;

for it=1:ntrials
    spike_time_trials = ds.resp.rawSpikeTimes{it};
    ns = length(spike_time_trials);
    spike_array = zeros(1, ntimebins);
    
    for is=1:ns
        time_ind = round(spike_time_trials(is)) + before_stim;
        if (time_ind < 1 || time_ind > ntimebins)
            fprintf(1, 'Warning time index in plot_one_spike out of bounds: time_ind = %d\n', time_ind);
            continue;
        end
        spike_array(time_ind) = spike_array(time_ind) +1;
    end
    psth = psth + spike_array;
    
    if (it < nplot)
        subplot('position',[0.13 0.66-it*(0.3/nplot) 0.775 (1-0.05)*0.3/nplot]);
        hold on;
        for j=1:ntimebins
            if (spike_array(j) > 0 )
                plot([t(j) t(j)],[0 spike_array(j)],'k');
            end
        end
        axis([-before_stim/1000.0 (stim_length + after_stim)/1000.0 0 1]);
        axis off;
    end
end
psth = psth./ntrials;

subplot(3,1,3)
wind1 = hanning(31)/sum(hanning(31));   % 31 ms smoothing
smpsth = conv(psth,wind1);
plot(t,smpsth(16:length(smpsth)-15)*1000);
axis([-before_stim/1000.0 (stim_length + after_stim)/1000.0 0 1000*max(smpsth)]);
ylabel('Rate (spikes/s)')
xlabel('Time (s)')
