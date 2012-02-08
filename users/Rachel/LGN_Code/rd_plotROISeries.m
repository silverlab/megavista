
plotfigs = 1;

roi = lgnROI1;
roi_mean = lgnROI1Mean;

%% Data collection params
nCycles = 8; % number of cycles per run (8)
nTRsPerCycle = 10; % number of TRs per cycle (10)
TR = 3; % TR duration (3 secs)

nTRsPerTrial = nCycles*nTRsPerCycle;

%% Generate the model (sine wave) time series
t = 1:nTRsPerTrial;
amp = 1;
phase = 0;
freq = 1/nTRsPerCycle*(2*pi);

model = amp*sin(freq*t + phase);

%% plot time series
if plotfigs
    figure
    hold on
    p1 = plot(t, roi);
    plot(t, roi_mean, 'LineWidth', 2)
    plot(t, model, '--k', 'LineWidth', 2)
    for iP1 = 1:length(p1)
        set(get(get(p1(iP1),'Annotation'),'LegendInformation'),...
            'IconDisplayStyle','off');
    end
    legend('Mean', 'Model')
    xlabel('Time (TRs)')
    ylabel('% signal change')
end